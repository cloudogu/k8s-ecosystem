# Releasing the EcoSystem Development Baseboxes

0. Make a release of k8s-ecosystem, if not already existent
    - Run `git flow release start vX.Y.Z` from develop
    - Adapt and commit changelog
    - Run `git flow release finish -s vX.Y.Z`
    - Push via `git push origin main` and `git push origin develop --tags`
1. Build a basebox as described in [Building Basebox](building_basebox_en.md)
2. Add a version to the basebox
    - Change the basebox name from `image/dev/build/ecosystem-basebox.box` to `image/dev/build/basebox-mn-vX.Y.Z.box`
3. Create a new folder `vX.Y.Z` in the corresponding [Google Cloud Bucket](https://console.cloud.google.com/storage/browser/cloudogu-ecosystem?project=cloudogu-backend)
4. Upload the box to the corresponding versioned folder
    - e.g. upload the `image/dev/build/basebox-mn-v1.0.0.box` into the `basebox-mn/v1.0.0/` folder
5. Edit the file's access permissions
    - Add an entry "Public/allUsers" and grant it "Reader" permissions
6. Adapt the Vagrantfile to match the newly released box
    - Adapt the basebox_version (to `vX.Y.Z`)
    - Adapt the basebox_checksum (get it via `sha256sum image/build/basebox-mn-v1.0.0.box`)
    - Test it via `vagrant up`
    - Commit and push
