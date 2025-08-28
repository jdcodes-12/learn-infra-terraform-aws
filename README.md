# Terraform on AWS 

## Requirements
1. AWS account
2. Terraform (Version 1.x.x <)
3. AWS group with the following permissions:
    - AmazonDyanmoDBFullAccess
    - AmazonS3FullAccess
    - AmazonRDSFullAccess
    - AmazonEC2FullAccess
    - AmazonRoute53FullAccess
    - IAMFullAccess

4. An AWS user, which will be added the the group.

Optional:
- aws cli (to help spinup VMs instead of using GUI)

## Configuring AWS CLI
1. Run `aws configure`

