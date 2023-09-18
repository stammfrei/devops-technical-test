output "public_url" {
    value = aws_lb.wordpress_http.dns_name
}
