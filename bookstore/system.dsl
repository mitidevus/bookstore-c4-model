workspace extends ../system-catalog.dsl {
    name "Bookstore Platform"
    description "Internet bookstore platform"
    model {
        !element bookstoreSystem {
            # Level 2: Containers
            # <variable> = container <name> <description> <technology> <tag>
            frontstoreApp = container "Front-store Application" "Provide all the bookstore functionalities to both public and authorized users" "JavaScript, ReactJS"
            backofficeApp = container "Back-office Application" "Provide all the bookstore administration functionalities to internal users" "JavaScript, ReactJS"
            searchWebApi = container "Search API" "Allows only authorized users searching books records via HTTPS API" "Go"
            searchDatabase = container "Search Database" "Stores searchable book data" "ElasticSearch" "Database"
            publicWebApi = container "Public Web API" "Allows public users getting books information via HTTPs API" "Go"
            adminWebApi = container "Admin Web API" "Allows only authorized users administering books details via HTTPS API" "Go" {
                # Level 3: Components
                # <variable> = component <name> <description> <technology> <tag>
                bookService = component "Book Service" "Allows administrating book details" "Go"
                authService = component "Authorizer" "Authorize users by using external Authorization System" "Go"
                bookEventPublisherService = component "Book Events Publisher" "Publishes books-related events to Book Event System" "Go"
            }
            bookstoreDatabase = container "Bookstore Database" "Stores book details" "PostgreSQL" "Database"
            bookEventSystem = container "Book Event System" "Handles book-related domain events" "Apache Kafka 3.0"
            bookEventConsumer = container "Book Event Consumer" "Listening to domain events and write publisher to Search Database for updating" "Go"
            publisherRecurrentUpdater = container "Publisher Recurrent Updater" "Listening to external events from Publisher System, and update book information" "Go"
        
            # Relationship between Containers
            publicUser -> frontstoreApp "Browse books" "JSON/HTTPS"
            authorizedUser -> frontstoreApp "Browse books" "JSON/HTTPS"
            frontstoreApp -> publicWebApi "Get book and place order information" "JSON/HTTPS"
            frontstoreApp -> searchWebApi "Search books" "JSON/HTTPS"

            internalUser -> backofficeApp "Administrate book details" "JSON/HTTPS"
            backofficeApp -> adminWebApi "Administrate books and purchases" "JSON/HTTPS"

            authorizedUser -> searchWebApi "Search book with more details" "JSON/HTTPS"
            searchWebApi -> searchDatabase "Retrieve book search data" "ODBC"
            bookEventConsumer -> searchDatabase "Write book update data" "ODBC"

            publicUser -> publicWebApi "View book information" "JSON/HTTPS"
            publicWebApi -> searchDatabase "Retrieve book search data" "ODBC"
            publicWebApi -> bookstoreDatabase "Read/Write book detail data" "ODBC"

            # authorizedUser -> adminWebApi "Administrate books and their details" "JSON/HTTPS"
            internalUser -> adminWebApi "Manage books and purchases information" "JSON/HTTPS"
            adminWebApi -> bookstoreDatabase "Read/Write book detail data" "ODBC"
            adminWebApi -> bookEventSystem "Publish book update events" "JSON/HTTPS" {
                tags "Async Request"
            }

            bookEventSystem -> bookEventConsumer "Publish and forward the book events" {
                tags "Async Request"
            }
            # bookEventSystem -> bookEventConsumer "Consume book update events"

            publisherRecurrentUpdater -> adminWebApi "Makes API calls to update book details" "JSON/HTTPS"


            # Relationship between Containers and External System
            searchWebApi -> authSystem "Authorize user" "JSON/HTTPS"

            adminWebApi -> authSystem "Authorize user" "JSON/HTTPS"

            publisherSystem -> publisherRecurrentUpdater "Publish book publication update events" {
                tags "Async Request"
            }

            # Relationship between Components
            internalUser -> adminWebApi.bookService "Administrate book details" "JSON/HTTPS"
            publisherRecurrentUpdater -> adminWebApi.bookService "Makes API calls to" "JSON/HTTPS"
            adminWebApi.bookService -> adminWebApi.authService "Uses"
            adminWebApi.bookService -> adminWebApi.bookEventPublisherService "Uses"

            # Relationship between Components and Other Containers
            adminWebApi.authService -> authSystem "Authorize user permissions" "JSON/HTTPS"
            adminWebApi.bookService -> bookstoreDatabase "Read/Write book details" "ODBC"
            adminWebApi.bookEventPublisherService -> bookEventSystem "Publish book-related events" {
                tags "Async Request"
            }
        }

        developer = person "Developer" "Internal bookstore platform developer" "User"

        deployWorkflow = softwareSystem "CI/CD Workflow" "Workflow CI/CD for deploying system using AWS Services" "Target System" {
            repository = container "Code Repository" "" "Github"
            pipeline = container "CodePipeline" {
                tags "Amazon Web Services - CodePipeline" "Dynamic Element"
            }
            codeBuilder = container "CodeBuild" "" {
                tags "Amazon Web Services - CodeBuild" "Dynamic Element"
            }
            containerRegistry = container "Amazon ECR" {
                tags "Amazon Web Services - EC2 Container Registry" "Dynamic Element"
            }
            cluster = container "Amazon EKS" {
                tags "Amazon Web Services - Elastic Kubernetes Service" "Dynamic Element"
            }

            developer -> repository
            repository -> pipeline
            pipeline -> codeBuilder
            codeBuilder -> containerRegistry
            codeBuilder -> pipeline
            pipeline -> cluster
        }
    }
    views {
        # Level 1
        systemContext bookstoreSystem "SystemContext" {
            include *
            # default: tb,
            # support tb, bt, lr, rl
            autoLayout lr
        }
        # Level 2
        container bookstoreSystem "Containers" {
            include *
            autoLayout lr
        }
        # Level 3
        component bookstoreSystem.adminWebApi "Components" {
            include *
            autoLayout lr
        }
        # Dynamic <container> <name> <description>
        dynamic deployWorkflow "Dynamic-001-WF" "Bookstore platform deployment workflow" {
            developer -> deployWorkflow.repository "Commit, and push changes"
            deployWorkflow.repository -> deployWorkflow.pipeline "Trigger pipeline job"
            deployWorkflow.pipeline -> deployWorkflow.codeBuilder "Download source code, and start build process"
            deployWorkflow.codeBuilder -> deployWorkflow.containerRegistry "Upload Docker image with unique tag"
            deployWorkflow.codeBuilder -> deployWorkflow.pipeline "Return the build result"
            deployWorkflow.pipeline -> deployWorkflow.cluster "Deploy container"
            autoLayout lr
        }
        
        theme default
    }
}