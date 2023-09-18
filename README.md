# Technical test

## Assignment

DEVOPS TEST : ## OPS terraform / ansible / packer / docker test
For this exercise, we would like you to use tools like Terraform, Packer, and Ansible.

The goal is to set up a WordPress container on an ECS cluster.

We would like you to use Packer with the Ansible provisioner to create a "ready to use"
WordPress image that will use an rds database. The goal is not to use a fork but to do
it by yourself. We are interested in the “how” and the result.

You can use AWS free tier usage: don't waste money!

We would like you to publish your image on a git repository (Github or BitBucket),
with a README file explaining:

- How did you approach the test?
- How did you run your project?
- What components interact with each other
- What problems did you encounter?
- How would you have done things to achieve the best HA/automated architecture?
- Please share any ideas you have to improve this kind of infrastructure

In the README, please also answer the following question:
Tomorrow we want to put this project in production. What would be your advice 
and choices to achieve that? In other words, the infrastructure and external
services like monitoring, etc.

As this test is done in your free time, we understand if it's not perfect or if
you don’t have time to go deeper.

Just tell us in the README file how you would have done this.

## Quick start

#### Generate AWS IAM administrator account

Links :
- [Getting started with ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html)

#### Get the dependencies

You can use either [docker](https://www.docker.com/) or [nix](https://nixos.org/).

##### Via nix 

1. You can install nix [using the determinate installer](https://github.com/DeterminateSystems/nix-installer)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

2. Start the devshell with the following command :

```bash
nix develop --extra-experimental-features "nix-command flakes"
```

##### Via docker

##### Use [docker](https://www.docker.com/)

1. [Install docker engine for your platform](https://docs.docker.com/engine/install/)

2. Use docker compose to execute the container :

```bash
docker compose run --rm nix-shell <command>
```

> First startup will be slow and it's normal, nix will fetch all the packages
> before giving you a prompt.


#### Review and export the required variables in :

- [The registry file](./terraform/registry/registry.tf)
- [The ecs variable file](./terraform/ecs/variables.tf)

The secrets must be provisioned via env vars, you need to provision :

```bash
AWS_ACCESS_KEY
AWS_SECRET_KEY
AWS_DEFAULT_REGION
TF_VAR_db_username
TF_VAR_db_password
```

4. Configure the tf backend

Either use the local backend or you can use [s3](https://aws.amazon.com/s3/), see
the [registry](./registry.s3.tfbackend) and [ecs](./ecs.s3.tfbackend) example files
and the [terraform docs](https://developer.hashicorp.com/terraform/language/settings/backends/s3).

5. Execute the deploy script :

> Note: All scripts must be executed from project root.

- Using nix
```bash
nix develop --extra-experimental-features "nix-command flakes"
./ci/deploy.sh full-deploy
```

- Using docker :
```bash
docker compose run --rm nix-shell ./ci/deploy.sh
```

> If you do not want interactive appoval in terraform, set the `TF_AUTO_APPROVE`
> env var to `true`

```bash
export TF_AUTO_APPROVE="true"
```

#### Destroy infrastructure

Just call the `./ci/deploy.sh destroy` script :

- Using nix
```bash
nix develop --extra-experimental-features "nix-command flakes"
./ci/deploy.sh destroy
```

- Using docker :
```bash
docker compose run --rm nix-shell destroy
```

---

## Response

### How did you approach the test ?

I was confident (maybe a little too mutch) because I implemented something similar
while working at Leocare. Using azure, vms and docker.

#### Build phase

The build part took me longer that expected. 

I first made an "hello-world" using packer to just get started and understand 
how to package a docker container using packer.

Then I started to create the wordpress image. I wanted to have a basic image
listening on :80 and be able to test it on my local machine first.

Using packer and ansible make for pretty slow build times. As far as I know :

- Packer doesn't cache builds
- Multi stage build are "manual" (I made a script for splitting the build stage
  in two to speed up my feedback loop)
- ansible is slow too (disabling facts help, but it's still way slower.

Since the full build pipeline was very slow with packer. I did a small poc using
Dockerfile to iterate faster to my desired config.

- I first wanted to make a debian based php-fpm image with nginx (it was the stack
  I used back at Leocare) but I got some weird error messages using fpm so I
  fallbacked to apache2.

- I created a working wordpress container using apache2 and dockerfile and tested
  it with `docker compose`.

- I wanted to be able to configure the container using env vars so I modified the
  [wp-config.php](./packer/ansible/templates/wp-config.php.j2).

- Once everything was working as expected, I ported all the build to packer using
  ansible.

- I had some quirks around permissions and entrypoint, but got it running.

#### Basic Deployment

I then started to lookup how all the stack would work with the requisites. Once
I understood ECS, ECR and RDS, I started a POC of the stack on AWS.

I first mounted a registry, and integrated the push with the `docker-push` 
post-processors in packer. I had at that stage a complete `build-and-push`
pipeline.

With the build out of the way I then focused myself on the ECS cluster.

My objective was to spin up a basic HTTP container with a public IP address to
grasp the requirements for the deployment.

It took me some time to look up and understand all the components involved to
get the whole stack running. I decided to use the FARGATE capacity provider to
skip EC2 management and making thing simpler.

I started very early to write the terraform code. In many case, following examples
was easier (and more detailed) than using the web UI.

#### Database and storage

Spinning an RDS database was very easy, but getting EFS to work wasn't easy.

As far as I tried, mounting an empty EFS volume to a path inside a container 
gives you an empty folder, so the wordpress folder pre-packaged inside the
container wasn't copied to the volume.

So I changed the entrypoint to be able to init the wordpress folder from an env
var.

#### Wrapping up whole pipeline

To iterate faster I coded the terraform manifest on the way. I took a bit of 
time at the end to clean up the code a bit.

This repo is far from being production ready but it should allow you to spawn
a wordpress container working on HTTP Port.

As requested, there are no DNS management, so I didn't address TLS either. But 
it should be a pre-requisite before pushing this to production.

### How did I run my project

I used [nix shells](https://nix.dev/tutorials/learning-journey/shell-dot-nix) to
handle the project dependencies since I am using [NixOS](https://nixos.org/).

I wrote all my dev/deploy script on a specific folder [ci](./ci). This a convention
I always use. I write all the project logic in .sh files, document them and use
them for `ci` (in most cases, i don't like to be 100% dependent on CI/CD to deploy
things. I want them to work both on my environment (nix shell) and on the CI).

I inject all the secrets via environment variables, the required ones are in the
[.env](./.env) file. I use [1password](https://1password.com/) as my secret manager
so I used `op run` to execute my scripts with the env var provisionned.

### What component interact with each others ?

At top level we got an aws region that contains :

#### Networking

We got a top level network called a VPC (Virtual Private Cloud) we that we link
to :

- A security group to manage firewall rules
- A routing table to manage routes
- A gateway for outgoing / ingoing
- DHCP configuration (generated by amazon)

I splitted this VPC in two subnet (I wanted only one at first, but RDS and LB 
want two subnet in two availability zone).

each subnet is in a different availability zone (that are seperate data center provided
by AWS).

#### Registry

The registry is a repository made to store one image close (in term of networking)
to the ECS cluster.

#### ECS

ECS is a container orchestrator that can schedule workloads across either some EC2
instances or inside [FARGATE](https://aws.amazon.com/fargate/).

To spawn a container you need :

- A task (A container running somewhere)
- A task definition (a template for executing a task)
- A service: schedule tasks across the cluster, either as replica (x container 
  must run somewhere on the cluster) or as DAEMON (One replica per EC2 instance)
- An IAM role: to define the permissions of a task (required e.g. for pulling
  images from a registry)
- (Optional): A cloudwatch log_group with a kms key to export log to AWS Cloudwatch.
- (Optional): An EFS volume for data persistence in containers (Looks like NFS
  version AWS)

#### HTTP

To expose a container you need a load balancer. To expose the wordpress container
that is a HTTP service we need :

- An application load balancer : this is the top level logical unit, we link it
  to our 2 subnets and the security group.
- A load balance listener : This is the effective endpoint listening to a port
  on a public IP and routing the requests to a load balancer target group
- The load balancer target group is a group of "endpoints" where the load
  balancer points to. It seems that AWS LB groups works by tasks "registering" to the
  group instead of the inverse.

#### RDS

For the database, I made a RDS instance. It seem to be a managed database working
on EC2 instances.

It uses a Subnet group to expose the database to 2 subnets in 2 availability zone.
It also binds to the security group.

I wonder if there is a load balancer abtracted behind this (or maybe just two 
network interfaces ?).

I didn't look up a lot the documentation on this side.

RDS can use a s3 bucket to export backups.


### Whet problems did I encounter ?

The main issues that took me time where :

- IAM management (attaching a role to the task definition for registry access
  and task execution): The policy I configured is still too wide. With more time
  for testing I could trim it down. I made it large to move forward (and the docs
  wansn't very clear about the minimal required permissions)

- Networking: I tried to spin up a VPC, with one subnet and a security group, but
  I missed a lot a thing (gateway, second subnet, routing table and loadbalancers).
  I used the defaults one, analyzed the default config and then recreated it and
  made it work.

  I was used to azure networking model that abstract more things.

  The load balancer part was easy to set up once the networking was done right.

- Some weird issues with ECS (probably things I didn't had time to understand):
  - Getting all the settings right for using FARGATE as a provider.
  - ECS rootless containers can't expose on port 80 ? I had to make my container
    listen on port 8080.
  - It took me some time to understand where all the informations where (tasks 
    spawn error don't always display on the event tab, but only on the task
    dashboard)
  - Tasks get a weird network timeout error if they don't get a public IP ?

- Wordpress doesn't have a healthcheck path, and aws application lb listeners 
  requires a working healthcheck to expose the container. This made the
  troubleshooting more complicated. I made a workaround but implementing a real
  healthcheck should be necessary.

### How would I have done things to achieve the best HA/automated architecture?

The real answer here is 'It depends' (on you needs, traffic, do you need 100%
consistency ? etc...).

So, first : TLS

Second : Backups, backups, backups with 3, 2, 1 rule for RDS and the EFS module.

Since we are going with an ECS cluster, I would have used 3 availability zones 
with 3 subnets and dispatched containers in all 3 zones. I would try to manage
autoscaling depending on traffic history. Wordpress can chew a lot of requests.

I would spin either a RDS cluster or just a master / Replica (if the database
load is not very high. Database cluster can be hard to manage and less is more).

For wordpress I would implement a way to initialize a container from an existing
wordpress git repo or tarball for managing code deployment (themes, plugins, etc)
purely via git, and manage all the assets via S3/EFS storage. And, unless ansible
and packer are a hard requirement, I would fall back to docker file and use official
provided image. (php done right is hard, let people who know do the heavy lifting).
And add a proper healthcheck.

Finally, implement test for the whole chain, every changes on the manifest should
be tested before deploying to production.

### Please share any ideas you have to improve this kind of infrastructure

Wordpress means security nightmare, I would add a Wordpress means security
nightmare, I would add a [WAF](https://aws.amazon.com/waf/) in front to protect it. 

Since wordpress is a website generator, I would need a [CDN](https://aws.amazon.com/cloudfront/)
to manage assets and speed up page loading and get that sweet good SEO rating.

> Tomorrow we want to put this project in production. What would be your advice 
> and choices to achieve that? In other words, the infrastructure and external
> services like monitoring, etc.

My primary concern would be security, so we need to implement :

- TLS
- Backups with automated restore tests.
- Skinned down IAM policies
- Precise firwall rules
- Add a WAF upfront
- Move and protect /wp-admin routes
- Disable or put the api behind authentication (xmlrpc.php)
- Make container FS Read only as mutch as possible (except the required folders)

Then content delivery and availability :

- External monitoring : [Grafana cloud](https://grafana.com/products/cloud/) or
[datadog](https://www.datadoghq.com/).
- Website status page and backup jobs monitoring, with e.g. [cronitor](https://cronitor.io)
- Add A CDN
- Manage cache (either via wordpress or AWS (or both))
- Fine tune container and database CPU/Memory/IOPS provisioning according to traffic

