# Steps

This document describe all the steps I took to execute the tasks

## Read the assignment

## Lookup definitions and tech required

- What is RDS, ECS.
- Refresh my knowledge of packer

### Making a hello world with packer

## Make a first dumb implementation with the least friction possible.

### Create a first basic image build

#### 1. Tried to make a wordpress php-fpm container with nginx

I got too mutch issue I couldn't solve quickly using php. So I changed the
solution used.

#### 2. Made a poc with apache2 using dockerfiles

Yes, dockerfile handles cache in the contrary of packer (as far as I know, I am
not a packer expert).

So I did an easy working solution with apache2, php using debian.

#### 3. port the build to packer

I rebuilded the container using packer, and I splitted the build in 'multi-stage'
to gain some build time when debugging things.

I added a docker-compose file to test it out.

### Try to spawn the required infrastructure manually on aws

The objective here is to see how aws works globally an what components I will
need for my deployment.

I want for now a very simple stack with one wordpress container, one database
and maybe a gateway.

#### 1. how to create a registry and push my container
