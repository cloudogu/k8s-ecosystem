# Keycloak preparation for CES use

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
    - Add to ID token: On (Maybe not needed?)
    - Add to access token: On (Maybe not needed?)
    - Add to userinfo: On
    - Add to token introspection: On (Maybe not needed?)

