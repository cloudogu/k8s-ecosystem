# Structure of the Project Files

The directory `image` contains the following files:

```
📦image
 ┣ (📂 build)             - Contains the resulting baseboxes after building them.
 ┣ 📂 http                - Contains information for Subiquity (the Ubuntu installer since 20.04) for:
 ┃ ┗ 📂 dev                  - the developmen baseboxes.
 ┃ ┗ 📂 prod                 - the production images.
 ┣ 📂 scripts             - Contains various scripts:
 ┃ ┗ 📂 dev                 - Development scripts executed when building the development baseboxes and instances.
 ┃ ┗ 📂 kubernetes          - Scripts regarding the setup of k8s.
 ┃ ┗ 📜 *.sh                - general scripts applying to all images and baseboxes.
 ┣ 📂 dev
 ┃ ┗ 📜 k8s-dev.pkr.hcl         - Packer template used to build the development basebox.
 ┣ 📂 prod
   ┗ 📜 k8s-prod.pkr.hcl        - Packer template used to build the production images for multiple hypervisors.
```