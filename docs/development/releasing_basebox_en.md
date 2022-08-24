# Releasing the EcoSystem Development Baseboxes

1. Build a basebox as described in [Building Basebox](building_basebox_en.md)
2. Add a version to the basebox
    - Main: Change the basebox name from `images/build/ecosystem-basebox-main.box` to `images/build/basebox-mn-main-vX.Y.Z.box`
    - Worker: Change the basebox name from `images/build/ecosystem-basebox-worker.box` to `images/build/basebox-mn-worker-vX.Y.Z.box`
3. Create a new folder `vX.Y.Z` in the corresponding [Google Cloud Bucket](https://console.cloud.google.com/storage/browser/cloudogu-ecosystem?project=cloudogu-backend)
4. Upload the box to the corresponding versioned folder
    - e.g. upload the `images/build/basebox-mn-main-v1.0.0.box` into the `basebox-mn-main/v1.0.0/` folder
5. Edit the file's access permissions
    - Add an entry "Public/allUsers" and grant it "Reader" permissions
6. Adapt the Vagrantfile to match the newly released box
    - Adapt the version (to `vX.Y.Z`)
    - Adapt the checksum (get it via `sha256sum image/build/basebox-mn-main-v1.0.0.box`)
    - Commit and push