# Infrastructure Architecture

This document breaks down the infrastructure architecture into smaller, more manageable components for better visualization and understanding.

## 1. Network Architecture (VPC)

```mermaid
graph TD
    subgraph vpc[VPC 10.0.0.0/16]
        subgraph az1[AZ 1]
            pub1[Public Subnet 1]
            priv1[Private Subnet 1]
            NAT1[NAT Gateway 1]
            pub1 --> NAT1
            NAT1 --> priv1
        end
        subgraph az2[AZ 2]
            pub2[Public Subnet 2]
            priv2[Private Subnet 2]
            NAT2[NAT Gateway 2]
            pub2 --> NAT2
            NAT2 --> priv2
        end
        IGW[Internet Gateway]
        IGW --> pub1
        IGW --> pub2
    end

    classDef az fill:#f9f,stroke:#333
    classDef public fill:#ccf,stroke:#333
    classDef private fill:#cdf,stroke:#333
    class az1,az2 az
    class pub1,pub2 public
    class priv1,priv2 private
```

## 2. EKS Cluster Architecture

```mermaid
graph TD
    subgraph eks[EKS Cluster]
        CP[Control Plane]
        subgraph ng[Node Groups]
            N1[Node 1]
            N2[Node 2]
        end
        subgraph addons[Core Add-ons]
            KP[Kube Proxy]
            DNS[CoreDNS]
            CNI[VPC CNI]
        end
        CP --> N1 & N2
        N1 & N2 --> addons
    end
    User[Developer] -->|kubectl| CP

    classDef cluster fill:#f9f,stroke:#333
    classDef control fill:#ffcc00,stroke:#333
    classDef nodes fill:#cdf,stroke:#333
    class eks cluster
    class CP control
    class N1,N2 nodes
```

## 3. Database Layer

```mermaid
graph TD
    subgraph db[RDS Infrastructure]
        Primary[RDS Primary]
        Standby[RDS Standby]
        SM[Secrets Manager]
        Primary ---|Replication| Standby
        SM -->|Credentials| Primary
        SM -->|Credentials| Standby
    end
    Apps[Application Pods] --> Primary
    Apps -.->|Failover| Standby

    classDef db fill:lightblue,stroke:#333
    classDef sm fill:#ffcc00,stroke:#333
    class Primary,Standby db
    class SM sm
```

## 4. State Management

```mermaid
graph TD
    TF[Terraform/Terragrunt] --> S3[S3 Bucket]
    TF --> DDB[DynamoDB Table]
    subgraph state[State Management]
        S3 -->|Stores State| StateFiles[State Files]
        DDB -->|Handles| Lock[State Locking]
    end

    classDef state fill:#f9f,stroke:#333
    class state state
```

Each environment (dev, staging, prod) follows this architecture pattern but with different configurations and resource sizes appropriate for their purpose.
