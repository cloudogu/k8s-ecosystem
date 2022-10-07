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
 ┣ 📜 k8s-dev.json        - Packer template used to build the development basebox.
 ┗ 📜 k8s-prod.json       - Packer template used to build the production images for multiple hypervisors.
```