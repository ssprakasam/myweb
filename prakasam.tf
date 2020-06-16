
provider "aws" {
    region = "ap-south-1" 
    profile = "ssp"
	}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP SSH inbound traffic"
  vpc_id      = "vpc-e1e5f889"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "my_http"
  }
}

resource "aws_s3_bucket" "mybucket123" {
  bucket = "hwabucket" 
  acl    = "public-read"
 }

resource "aws_s3_bucket_object" "s3object" {
  bucket = "hwabucket"
  key    = "prakasam.jpg"
  source = "C:/Users/ps226/Desktop/AWS/prakasam.jpg"
 
} 


resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "This is origin access identity"
}

resource "aws_cloudfront_distribution" "imagecf" {
    origin {
        domain_name = "hwabucket.s3.amazonaws.com"
        origin_id = "S3-hwabucket"


        s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
       
    enabled = true
      is_ipv6_enabled     = true

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-hwabucket"


        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 10
        max_ttl = 30
    }
    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }


    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}


resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "prakasam"
 

  connection {
    type     = "SSH"
    user     = "ec2-user"
    private_key = file("C:/Users/ps226/Desktop/AWS/prakasam.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "myweb"
  }

}

resource "aws_ebs_volume" "ebs_vol" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1

  tags = {
    Name = "mypendrive"
  }
}
resource "aws_volume_attachment" "EBS_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ebs_vol.id
  instance_id = aws_instance.web.id
  force_detach = true
}

output "myweb_ip" {
  value = aws_instance.web.public_ip
}

resource "null_resource" "null1"  {

  depends_on = [
    aws_volume_attachment.EBS_attachment,
  ]
  connection {
    type     = "SSH"
    user     = "ec2-user"
    private_key = file("C:/Users/ps226/Desktop/AWS/prakasam.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdf",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/ssprakasam/myweb.git /var/www/html/"
    ]
  }
}

