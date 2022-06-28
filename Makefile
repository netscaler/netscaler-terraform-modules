modules_docgen:
	terraform-docs aws/modules/aws_citrixadc > aws/modules/aws_citrixadc/README.md
	terraform-docs markdown aws/modules/aws_vpc_infra > aws/modules/aws_vpc_infra/README.md
	terraform-docs markdown aws/modules/aws_bastion > aws/modules/aws_bastion/README.md

fmt:
	terraform fmt -list=true -recursive aws/modules
	terraform fmt -list=true -recursive aws/usecases