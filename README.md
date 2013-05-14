# MyBlog Vagrant Demo

# Requirements
* Ruby 1.8.7 or greater (Ruby 1.9.3 is recommended)
* RubyGems 

# Installation
  * Install [VirtualBox](https://www.virtualbox.org/)
  * Install [Vagrant](http://vagrantup.com)
  * Install the necessary RubyGems
		
		gem install bundler
		bundle install

  * Install necessary vagrant plugins
  
		vagrant plugin install vagrant-aws
		vagrant plugin install vagrant-berkshelf

# Usage
## Creating the AWS Boxes
### Setting up AWS
The main Vagrantfile, as it is, will work out of the box with the VirtualBox provider. If you wish 
to use the AWS provider to spin up boxes, you will need to create and install the AWS boxes that
are provided in the `vagrant-aws` folder. 

You will need an active AWS account with an IAM user that has Read-Only access in addition to the following privileges:
		
		{
		  "Statement": [
		    {
		      "Sid": "Stmt1367693469134",
		      "Action": [
		        "ec2:Describe*",
        		"ec2:RunInstances",
		        "ec2:StartInstances",
		        "ec2:StopInstances",
		        "ec2:TerminateInstances"
		        "ec2:CreateTags",
		        "ec2:CreateVolume",
		        "ec2:DeleteVolume",
		        "ec2:GetConsoleOutput",
		        "ec2:RebootInstances",
		        "ec2:ReportInstanceStatus",
		        "ec2:ResetInstanceAttribute"
		      ],
		      "Effect": "Allow",
		      "Resource": [
		        "*"
		      ]
		    }
		  ]
		}

You will need to update the `aws.access_key_id` and `aws.secret_access_key` fields for each `Vagrantfile` in the `vagrant-aws` folder with the associated values for the IAM user you created above. 

	…
	
	config.vm.provider :aws do |aws, override|
    	aws.access_key_id = ""
    	aws.secret_access_key = ""
    
    …


In addition to the IAM user you will need to create and download into each box folder an AWS Key Pair (each box can use the same keypair). Make sure to update the `Vagrantfile` with the appropriate filename of your Key Pair. 

	  config.vm.provider :aws do |aws, override|
	    … 
	    
	    aws.keypair_name = ""
	    
	    … 
	
	    override.ssh.private_key_path = File.expand_path('../your-private-key.pem', __FILE__)
	  end

AWS Security Groups will also need to be created and configured properly. 

* *wp-ops*: Open SSH to 0.0.0.0/0  
* *wp-web*: Open HTTP to 0.0.0.0/0  
* *wp-mysql*: Open MySQL to *wp-web*


You will also need to configure each `Vagrantfile` with an AMI that has chef-client pre-installed on it. Make sure to update the ssh username with the appropriate value.

	  config.vm.provider :aws do |aws, override|
	    … 
	    aws.ami = ""
		… 
	    override.ssh.username = "ubuntu"
	    … 
	  end



### Setting up Chef
The AWS boxes included in this repo are configured to work with an existing Chef Server. If 
you do not have a Chef Server, you can sign up for a free account at [http://opscode.com](http://opscode.com).

Once you have AWS setup, you will also need to configure each `Vagrantfile` with the appropriate Chef Server information. Like the AWS Key Pair, you will need to download the Validation Key associated with your Chef Server and store a copy of it in each of the aws folders. 

### Creating the Boxes
Once you have all the files downloaded and the `Vagrantfile` updated you will need to tar the contents of those folders into a box. 
			
		cd vagrant-aws
		tar -cxvf backend/backend.box backend/*
		tar -cxvf frontend/frontend.box frontend/*
		tar -cxvf wordpress/wordpress.box wordpress/*
		
Once you have the boxes created, you will need to add them to Vagrant. 

		cd vagrant-aws
		vagrant box add backend backend/backend.box
		vagrant box add frontend frontend/frontend.box
		vagrant box add wordpress wordpress/wordpress.box
		

# Launching Machines

### Stand-alone Wordpress Blog in Local VirtualBox
		vagrant up wordpress

### Stand-alone Wordpress Blog in AWS
		vagrant up wordpress_aws --provider=aws

### Wordpress Blog with separate front and backends
		vagrant up backend_aws frontend_aws --provider=aws

# Recipes
### myblog::default
Installs a self-contained wordpress blog on a single server.

### myblog::frontend
Installs and configures an Apache frontend server with Wordpress.

### myblog::backend
Installs and configures a MySQL Server.

# Author
Author:: Tom Duffield (@tomduffield)  
Author:: Michael Goetz (@michaelpgoetz)
