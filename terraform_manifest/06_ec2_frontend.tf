# Public EC2 Instance
resource "aws_security_group" "public_ec2_ssh" {
  name        = "public_ec2_ssh"
  description = "public_ec2_ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.POC-01.id
}

resource "aws_instance" "public_instance" {
  ami                    = "ami-0b09627181c8d5778"
  instance_type          = "t2.micro"
  key_name               = "temp-key"
  subnet_id              = aws_subnet.Public-subnet-1.id
  vpc_security_group_ids = [aws_security_group.public_ec2_ssh.id]
  
}

# # Private EC2 Instance

# resource "aws_security_group" "private_ec2" {
#   name        = "private_ec2"
#   description = "private_ec2"

#   # ingress {
#   #   from_port   = 0
#   #   to_port     = 0
#   #   protocol    = "-1"
#   #   cidr_blocks = ["0.0.0.0/0"]
#   # }


#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   vpc_id = aws_vpc.project-01.id
# }
# resource "aws_security_group_rule" "all_traffic_from_msk" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "-1"
#   security_group_id        = aws_security_group.private_ec2.id
#   source_security_group_id = aws_security_group.sg.id
#   depends_on               = [aws_security_group.sg]
# }
resource "aws_security_group_rule" "http_access_from_public" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public_ec2_ssh.id
}



# resource "aws_instance" "private_instance" {
#   ami                    = var.ami_id
#   instance_type          = "t2.micro"
#   key_name               = "temp-key"
#   subnet_id              = aws_subnet.Private-subnet-1.id
#   vpc_security_group_ids = [aws_security_group.private_ec2.id]
#   user_data              = <<EOF
# #!/bin/bash
# yum install -y java-1.8.0-openjdk wget nc

# cd /home/ec2-user
# wget https://archive.apache.org/dist/kafka/2.8.1/kafka_2.12-2.8.1.tgz
# tar -xvf kafka_2.12-2.8.1.tgz
# cd kafka_2.12-2.8.1

# BOOTSTRAP="${aws_msk_cluster.lambda-project.bootstrap_brokers}"
# TOPIC="${var.kafka_topic_name}"

# cat <<EOT > /home/ec2-user/create_topic.sh
# #!/bin/bash

# BOOTSTRAP_REPLACE="$BOOTSTRAP"
# TOPIC_REPLACE="$TOPIC"

# for i in {1..10}; do
#   HOST=\$(echo "\$BOOTSTRAP_REPLACE" | cut -d',' -f1 | cut -d':' -f1)
#   nc -zv "\$HOST" 9092 && break
#   echo "Waiting for MSK to be ready..." >> /home/ec2-user/kafka_topic.log
#   sleep 30
# done

# /home/ec2-user/kafka_2.12-2.8.1/bin/kafka-topics.sh \
#   --create \
#   --topic "\$TOPIC_REPLACE" \
#   --bootstrap-server "\$BOOTSTRAP_REPLACE" \
#   --replication-factor 1 \
#   --partitions 2 >> /home/ec2-user/kafka_topic.log 2>&1
# EOT

# chmod +x /home/ec2-user/create_topic.sh
# nohup /home/ec2-user/create_topic.sh >> /home/ec2-user/kafka_topic.log 2>&1 &

# nohup /home/ec2-user/kafka_2.12-2.8.1/bin/kafka-console-consumer.sh \
#   --topic "${var.kafka_topic_name}" \
#   --bootstrap-server "${aws_msk_cluster.lambda-project.bootstrap_brokers}" \
#   --from-beginning >> /home/ec2-user/kafka_consumer.log 2>&1 &
# EOF


#   depends_on = [aws_msk_cluster.lambda-project]
# }