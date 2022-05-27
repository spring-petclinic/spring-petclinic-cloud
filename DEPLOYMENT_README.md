# Prerequisites
- [aws-cli v2.5.8](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [kubectl v1.23.6](https://kubernetes.io/docs/tasks/tools/)
- install **helm v3.8.0** - `./get_helm.sh --version v3.8.0`

# Deployment
1. Start **AWS** lab and paste **AWS CLI** (from **AWS Details**) credentials to `~/.aws/credentials`
2. Modify `./scripts/deploy.sh` script. 
Set ARN of [LabRole](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/roles/details/LabRole?section=permissions) to `LAB_ROLE` variable. 
Set two [subnet ID](https://us-east-1.console.aws.amazon.com/vpc/home?region=us-east-1#subnets:) to `SUBNET_A` and `SUBNET_B` variables.
3. Run `./scripts/deploy.sh` script
