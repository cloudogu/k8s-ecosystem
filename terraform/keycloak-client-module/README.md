# Keycloak preparation for CES use

This is a Terraform module for managing a Keycloak instance to be used with a CES for a federated login. 
The module uses a service account client to create a new Keycloak client for the ecosystem. This client is 
given to the CAS to integrate the keycloak login into the ecosystem. Learn how to configure the CAS 
[here](https://docs.cloudogu.com/en/docs/dogus/cas/operations/Configure_OIDC_Provider/).

## Create Keycloak Service Account Client

Create a new client in your desired Keycloak Realm that will get the access rights to create new clients for each CES 
instance. See [example json](ces-service-account-client-example.json).

Most important configurations:
- Settings:
  - Client type = OpenID Connect
  - Client authentication = On
  - Authorization = On
  - Service accounts roles = On
- Service accounts roles
  - create-clients
  - manage-clients
  - query-clients
  - view-authorization
  - view-clients

## Create ClientScope

Create a new ClientScope to be able to query group information for Keycloak-Users.

Configuration:
- Settings:
  - name: groups
  - type: Default
- Mappers:
  - group-Mapper
    - Mapper type: Group Membership
    - Name: groups
    - Token Claim Name: groups
    - Add to ID token: On
    - Add to access token: On
    - Add to userinfo: On
    - Add to token introspection: On
