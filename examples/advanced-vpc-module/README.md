# Advanced VPC Module

A comprehensive Terraform module for creating secure, scalable VPC infrastructure on AWS with best practices from HashiCorp.

## Features

- **Multi-AZ Support**: High availability across multiple availability zones
- **Public & Private Subnets**: Secure network segmentation
- **NAT Gateway**: Optional NAT gateway for private subnet internet access
- **Security Groups**: Pre-configured security groups for web and database tiers
- **VPC Flow Logs**: Optional network traffic monitoring
- **Comprehensive Tagging**: Consistent resource tagging strategy
- **Variable Validation**: Input validation for security and reliability
- **Modular Design**: Enable/disable features as needed

## Usage

### Basic Usage

```hcl
module "vpc" {
  source = "./advanced-vpc-module"

  environment = "prod"
  vpc_cidr_block = "10.0.0.0/16"
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  
  availability_zones = ["us-west-2a", "us-west-2b"]
  
  enable_nat_gateway = true
  enable_flow_logs   = true
  
  common_tags = {
    Project     = "my-project"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

### Advanced Usage

```hcl
module "vpc" {
  source = "./advanced-vpc-module"

  environment = "staging"
  vpc_cidr_block = "172.16.0.0/16"
  
  public_subnet_cidrs  = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  private_subnet_cidrs = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]
  
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  enable_nat_gateway = true
  enable_flow_logs   = true
  enable_web_security_group = true
  enable_database_security_group = true
  
  flow_log_retention_days = 30
  
  common_tags = {
    Project     = "web-application"
    Environment = "staging"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| vpc_cidr_block | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | List of CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| private_subnet_cidrs | List of CIDR blocks for private subnets | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24"]` | no |
| availability_zones | List of availability zones | `list(string)` | `["us-west-2a", "us-west-2b"]` | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| enable_web_security_group | Enable web security group | `bool` | `true` | no |
| enable_database_security_group | Enable database security group | `bool` | `true` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `false` | no |
| common_tags | Common tags for all resources | `map(string)` | `{}` | no |
| aws_region | AWS region | `string` | `"us-west-2"` | no |
| flow_log_retention_days | Flow log retention in days | `number` | `7` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| internet_gateway_id | The ID of the Internet Gateway |
| nat_gateway_id | The ID of the NAT Gateway |
| default_security_group_id | The ID of the default security group |
| web_security_group_id | The ID of the web security group |
| database_security_group_id | The ID of the database security group |
| module_summary | Summary of the module configuration |

## Security Features

### Security Groups

1. **Default Security Group**: Allows all internal traffic within the VPC
2. **Web Security Group**: Allows HTTP (80) and HTTPS (443) from anywhere
3. **Database Security Group**: Allows MySQL (3306) from web security group only

### Network Security

- Private subnets have no direct internet access
- NAT Gateway provides controlled internet access for private resources
- VPC Flow Logs enable network traffic monitoring
- Proper subnet isolation between public and private tiers

## Best Practices Implemented

1. **High Availability**: Multi-AZ deployment across availability zones
2. **Security**: Private subnets for sensitive resources
3. **Monitoring**: Optional VPC Flow Logs for network visibility
4. **Tagging**: Consistent resource tagging strategy
5. **Validation**: Input validation for CIDR blocks and environment names
6. **Modularity**: Conditional resource creation based on variables
7. **Documentation**: Comprehensive variable and output documentation

## Cost Considerations

- NAT Gateway incurs hourly charges (~$0.045/hour)
- VPC Flow Logs have CloudWatch Logs charges
- Consider using NAT Instance for development environments
- Use appropriate instance types for your workload

## Examples

### Development Environment

```hcl
module "vpc_dev" {
  source = "./advanced-vpc-module"
  
  environment = "dev"
  enable_nat_gateway = false  # Save costs in dev
  enable_flow_logs = false    # Save costs in dev
  
  common_tags = {
    Environment = "dev"
    Project     = "my-app"
  }
}
```

### Production Environment

```hcl
module "vpc_prod" {
  source = "./advanced-vpc-module"
  
  environment = "prod"
  enable_nat_gateway = true
  enable_flow_logs = true
  flow_log_retention_days = 90
  
  common_tags = {
    Environment = "prod"
    Project     = "my-app"
    CostCenter  = "engineering"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## License

This module is licensed under the MIT License.

## Support

For issues and questions, please refer to the HashiCorp Terraform documentation at https://developer.hashicorp.com/terraform 