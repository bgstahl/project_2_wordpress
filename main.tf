provider "aws" {
  region     = "us-east-1"
  access_key = "ASIAU3RKYJALTJGBGJVD"
  secret_key = "+cyKcmH7ADDyPN1GGcOVF7R1J5DP42C1vcAmSoq+"
  token = "FwoGZXIvYXdzEPf//////////wEaDMO6ZyA05/eKOXNtoCK7AS70+uU+RuoHG2QgPpzobfdjIou06r40Xrslec5scLLjWZ8UP5uXH7XC/0s8W7W8lrAt6xkQtSUhnYnGVG8uKEKQG04wAs9LjMT6dEpQQ1DSd8vZFYKZRk26A/7pAgKlxf9rQaHxY0DVivGjemRq6qYiuukD/EOY8erR+Nh/jb84vmy7CeG5UsNbNyKu/95859iOyQJ0EZGDWJEdkLGNxAZ5HS1OBGg0tNnl5kvUWBBa2Pno1dHNy6tT9uMo4JX/lAYyLcuhrSWhAn/w5Gg45OUbTz+Ns43TLmdw8QXhFmDnv1h68SL0iHb6c7a4HZGCTw=="
}

#Create security group that allows all SSH traffic in and out
resource "aws_security_group" "wordpress" {
        name   = "Wordpress"
        vpc_id = "vpc-0b5bcdff80a0b90a3"

        ingress {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }

        egress {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }

        tags = {
                Name = "Wordpress security group"
        }
}

resource "aws_instance" "wordpress" {
	ami           = "ami-0c4f7023847b90238"
	instance_type = "t2.micro"
	key_name      = "Wordpress"
        #Use security group ID of security group created above
        vpc_security_group_ids = [aws_security_group.wordpress.id]
	tags = {
		Name = "WordPress"
	}

	connection {
		type        = "ssh"
		host        = self.public_ip
		user        = "ubuntu"
		private_key = file("/home/benjamingstahlg/wordpress/Wordpress.pem")
		# Default timeout is 5 minutes
		timeout     = "4m"
	}

        #Creates a file on remote host to check connection has been established
	provisioner "remote-exec" {
		inline = [
			"touch /home/ubuntu/wordpress-host-test.txt"
		]
	}

        #Create an Ansible inventory file with host IP of created instance
        provisioner "local-exec" {
          command = "echo ${self.public_ip} | sudo tee -a /etc/ansible/hosts"
        }

        #Execute ansible playbook to deploy WordPress
        provisioner "local-exec" {
          command = "ansible-playbook playbook.yml -u ubuntu --private-key Wordpress.pem"
        }

}

output "wordpress_public_ip" {
  value = ["${aws_instance.wordpress.*.public_ip}"]
}
