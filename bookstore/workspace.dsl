workspace extends system.dsl {
    model {       
        # Deployment
        prodEnvironment = deploymentEnvironment "Production" {
            deploymentNode "AWS" {
                tags "Amazon Web Services - Cloud"

                route53 = infrastructureNode "Route 53" {
                    tags "Amazon Web Services - Route 53"
                }

                deploymentNode "ap-southeast-1" {
                    tags "Amazon Web Services - Region"

                    deploymentNode "prod-vpc" {
                        tags "Amazon Web Services - VPC"

                        infrastructureNode "CloudFront Distribution" {
                            tags "Amazon Web Services - CloudFront"
                        }

                        deploymentNode "S3 - Front-store App" {
                            tags "Amazon Web Services - Simple Storage Service S3"

                            containerInstance bookstoreSystem.frontstoreApp
                        }

                        appLoadBalancer = infrastructureNode "Application Load Balancer" {
                            tags "Amazon Web Services - Elastic Load Balancing ELB Application load balancer"
                        }

                        deploymentNode "private-net-a" {
                            tags "Amazon Web Services - VPC subnet private"
                            
                            deploymentNode "eks-cluster" {
                                tags "Amazon Web Services - Elastic Kubernetes Service"
                            
                                deploymentNode "ec2-a" {
                                    tags "Amazon Web Services - EC2 Instance"
                                    
                                    backofficeAppInstance = containerInstance bookstoreSystem.backofficeApp
                                    searchWebApiInstance = containerInstance bookstoreSystem.searchWebApi
                                    adminWebApiInstance = containerInstance bookstoreSystem.adminWebApi
                                    publicWebApiInstance = containerInstance bookstoreSystem.publicWebApi
                                    # publisherRecurrentUpdateInstance = containerInstance publisherRecurrentUpdater

                                    appLoadBalancer -> publicWebApiInstance "Forwards requests to" "[HTTPS]"
                                    appLoadBalancer -> searchWebApiInstance "Forwards requests to" "[HTTPS]"
                                    appLoadBalancer -> adminWebApiInstance "Forwards requests to" "[HTTPS]"
                                }
                            }
                        }

                        deploymentNode "private-net-b" {
                            tags "Amazon Web Services - VPC subnet private"
                            
                            deploymentNode "eks-cluster" {
                                tags "Amazon Web Services - Elastic Kubernetes Service"

                                deploymentNode "ec2-b" {
                                    tags "Amazon Web Services - EC2 Instance"

                                    containerInstance bookstoreSystem.bookEventConsumer
                                    containerInstance bookstoreSystem.bookEventSystem
                                }
                            }

                            deploymentNode "PostgreSQL RDS" {
                                tags "Amazon Web Services - RDS"
                                
                                containerInstance bookstoreSystem.bookstoreDatabase
                            }

                            deploymentNode "Amazon Elasticsearch" {
                                tags "Amazon Web Services - Elasticsearch Service"

                                containerInstance bookstoreSystem.searchDatabase
                            }
                        }

                        route53 -> appLoadBalancer
                    }
                }
            }
        }
    }

    views {
        # deployment <software-system> <environment> <key> <description>
        deployment bookstoreSystem prodEnvironment "Dep-001-PROD" "Cloud Architecture for Bookstore Platform using AWS Services" {
            include *
            autoLayout lr
        }

        theme "https://static.structurizr.com/themes/amazon-web-services-2020.04.30/theme.json"

        styles {
            element "Dynamic Element" {
                background #ffffff
            }
        }
    }
}
