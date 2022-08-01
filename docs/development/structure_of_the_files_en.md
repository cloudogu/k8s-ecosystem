# Structure of the Project Files

The directory `image` contains the following files:

```
📦image
 ┣ (📂 build)             - Contains the resulting base-boxes after building them.
 ┣ 📂 http                - Contains information for Subiquity, i. e., the new installer for Ubuntu > 20.04 for:
 ┃ ┗ 📂 dev                  - the developmen base-boxes.
 ┃ ┗ 📂 prod                 - the production images.
 ┣ 📂 scripts             - Contains various scripts:
 ┃ ┗ 📂 dev                 - Development scripts executed when building the development base-boxes and instances.
 ┃ ┗ 📂 kubernetes          - Scripts regarding the setup of k8s.
 ┃ ┗ 📜 *.sh                - general scripts applying to all images and base-boxes.
 ┣ 📜 k8s-dev-main.json   - Packer template used to build the development basebox for the main node.
 ┣ 📜 k8s-dev-worker.json - Packer template used to build the development basebox for the worker node.
 ┗ 📜 k8s-prod.json       - Packer template used to build the production images of multiple provisioners.
```