# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/gavinbunney/kubectl" {
  version     = "1.19.0"
  constraints = ">= 1.7.0"
  hashes = [
    "h1:9QkxPjp0x5FZFfJbE+B7hBOoads9gmdfj9aYu5N4Sfc=",
    "zh:1dec8766336ac5b00b3d8f62e3fff6390f5f60699c9299920fc9861a76f00c71",
    "zh:43f101b56b58d7fead6a511728b4e09f7c41dc2e3963f59cf1c146c4767c6cb7",
    "zh:4c4fbaa44f60e722f25cc05ee11dfaec282893c5c0ffa27bc88c382dbfbaa35c",
    "zh:51dd23238b7b677b8a1abbfcc7deec53ffa5ec79e58e3b54d6be334d3d01bc0e",
    "zh:5afc2ebc75b9d708730dbabdc8f94dd559d7f2fc5a31c5101358bd8d016916ba",
    "zh:6be6e72d4663776390a82a37e34f7359f726d0120df622f4a2b46619338a168e",
    "zh:72642d5fcf1e3febb6e5d4ae7b592bb9ff3cb220af041dbda893588e4bf30c0c",
    "zh:9b12af85486a96aedd8d7984b0ff811a4b42e3d88dad1a3fb4c0b580d04fa425",
    "zh:a1da03e3239867b35812ee031a1060fed6e8d8e458e2eaca48b5dd51b35f56f7",
    "zh:b98b6a6728fe277fcd133bdfa7237bd733eae233f09653523f14460f608f8ba2",
    "zh:bb8b071d0437f4767695c6158a3cb70df9f52e377c67019971d888b99147511f",
    "zh:dc89ce4b63bfef708ec29c17e85ad0232a1794336dc54dd88c3ba0b77e764f71",
    "zh:dd7dd18f1f8218c6cd19592288fde32dccc743cde05b9feeb2883f37c2ff4b4e",
    "zh:ec4bd5ab3872dedb39fe528319b4bba609306e12ee90971495f109e142d66310",
    "zh:f610ead42f724c82f5463e0e71fa735a11ffb6101880665d93f48b4a67b9ad82",
  ]
}

provider "registry.terraform.io/hashicorp/helm" {
  version     = "2.17.0"
  constraints = ">= 2.12.1, >= 2.13.2"
  hashes = [
    "h1:K5FEjxvDnxb1JF1kG1xr8J3pNGxoaR3Z0IBG9Csm/Is=",
    "zh:06fb4e9932f0afc1904d2279e6e99353c2ddac0d765305ce90519af410706bd4",
    "zh:104eccfc781fc868da3c7fec4385ad14ed183eb985c96331a1a937ac79c2d1a7",
    "zh:129345c82359837bb3f0070ce4891ec232697052f7d5ccf61d43d818912cf5f3",
    "zh:3956187ec239f4045975b35e8c30741f701aa494c386aaa04ebabffe7749f81c",
    "zh:66a9686d92a6b3ec43de3ca3fde60ef3d89fb76259ed3313ca4eb9bb8c13b7dd",
    "zh:88644260090aa621e7e8083585c468c8dd5e09a3c01a432fb05da5c4623af940",
    "zh:a248f650d174a883b32c5b94f9e725f4057e623b00f171936dcdcc840fad0b3e",
    "zh:aa498c1f1ab93be5c8fbf6d48af51dc6ef0f10b2ea88d67bcb9f02d1d80d3930",
    "zh:bf01e0f2ec2468c53596e027d376532a2d30feb72b0b5b810334d043109ae32f",
    "zh:c46fa84cc8388e5ca87eb575a534ebcf68819c5a5724142998b487cb11246654",
    "zh:d0c0f15ffc115c0965cbfe5c81f18c2e114113e7a1e6829f6bfd879ce5744fbb",
    "zh:f569b65999264a9416862bca5cd2a6177d94ccb0424f3a4ef424428912b9cb3c",
  ]
}

provider "registry.terraform.io/hashicorp/kubernetes" {
  version     = "2.35.1"
  constraints = "~> 2.30"
  hashes = [
    "h1:Av0Wk8g2XjY2oap7nyWNHEgfCRfphdJvrkqJjEM2ZKM=",
    "zh:12212ca5ae47823ce14bfafb909eeb6861faf1e2435fb2fc4a8b334b3544b5f5",
    "zh:3f49b3d77182df06b225ab266667de69681c2e75d296867eb2cf06a8f8db768c",
    "zh:40832494d19f8a2b3cd0c18b80294d0b23ef6b82f6f6897b5fe00248a9997460",
    "zh:739a5ddea61a77925ee7006a29c8717377a2e9d0a79a0bbd98738d92eec12c0d",
    "zh:a02b472021753627c5c39447a56d125a32214c29ff9108fc499f2dcdf4f1cc4f",
    "zh:b78865b3867065aa266d6758c9601a2756741478f5735a838c20d633d65e085b",
    "zh:d362e87464683f5632790e66920ea803adb54c2bc0cb24b6fd9a314d2b1efffd",
    "zh:d98206fe88c2c9a52b8d2d0cb2c877c812a4a51d19f9d8428e63cbd5fd8a304d",
    "zh:dfa320946b1ce3f3615c42b3447a28dc9f604c06d8b9a6fe289855ab2ade4d11",
    "zh:f569b65999264a9416862bca5cd2a6177d94ccb0424f3a4ef424428912b9cb3c",
    "zh:fc1debd2e695b5222d2ccc8b24dab65baba4ee2418ecce944e64d42e79474cb5",
    "zh:fdaf960443720a238c09e519aeb30faf74f027ac5d1e0a309c3b326888e031d7",
  ]
}

provider "registry.terraform.io/hashicorp/null" {
  version = "3.2.3"
  hashes = [
    "h1:+AnORRgFbRO6qqcfaQyeX80W0eX3VmjadjnUFUJTiXo=",
    "zh:22d062e5278d872fe7aed834f5577ba0a5afe34a3bdac2b81f828d8d3e6706d2",
    "zh:23dead00493ad863729495dc212fd6c29b8293e707b055ce5ba21ee453ce552d",
    "zh:28299accf21763ca1ca144d8f660688d7c2ad0b105b7202554ca60b02a3856d3",
    "zh:55c9e8a9ac25a7652df8c51a8a9a422bd67d784061b1de2dc9fe6c3cb4e77f2f",
    "zh:756586535d11698a216291c06b9ed8a5cc6a4ec43eee1ee09ecd5c6a9e297ac1",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:9d5eea62fdb587eeb96a8c4d782459f4e6b73baeece4d04b4a40e44faaee9301",
    "zh:a6355f596a3fb8fc85c2fb054ab14e722991533f87f928e7169a486462c74670",
    "zh:b5a65a789cff4ada58a5baffc76cb9767dc26ec6b45c00d2ec8b1b027f6db4ed",
    "zh:db5ab669cf11d0e9f81dc380a6fdfcac437aea3d69109c7aef1a5426639d2d65",
    "zh:de655d251c470197bcbb5ac45d289595295acb8f829f6c781d4a75c8c8b7c7dd",
    "zh:f5c68199f2e6076bce92a12230434782bf768103a427e9bb9abee99b116af7b5",
  ]
}

provider "registry.terraform.io/hashicorp/random" {
  version = "3.6.3"
  hashes = [
    "h1:Fnaec9vA8sZ8BXVlN3Xn9Jz3zghSETIKg7ch8oXhxno=",
    "zh:04ceb65210251339f07cd4611885d242cd4d0c7306e86dda9785396807c00451",
    "zh:448f56199f3e99ff75d5c0afacae867ee795e4dfda6cb5f8e3b2a72ec3583dd8",
    "zh:4b4c11ccfba7319e901df2dac836b1ae8f12185e37249e8d870ee10bb87a13fe",
    "zh:4fa45c44c0de582c2edb8a2e054f55124520c16a39b2dfc0355929063b6395b1",
    "zh:588508280501a06259e023b0695f6a18149a3816d259655c424d068982cbdd36",
    "zh:737c4d99a87d2a4d1ac0a54a73d2cb62974ccb2edbd234f333abd079a32ebc9e",
    "zh:78d5eefdd9e494defcb3c68d282b8f96630502cac21d1ea161f53cfe9bb483b3",
    "zh:a357ab512e5ebc6d1fda1382503109766e21bbfdfaa9ccda43d313c122069b30",
    "zh:c51bfb15e7d52cc1a2eaec2a903ac2aff15d162c172b1b4c17675190e8147615",
    "zh:e0951ee6fa9df90433728b96381fb867e3db98f66f735e0c3e24f8f16903f0ad",
    "zh:e3cdcb4e73740621dabd82ee6a37d6cfce7fee2a03d8074df65086760f5cf556",
    "zh:eff58323099f1bd9a0bec7cb04f717e7f1b2774c7d612bf7581797e1622613a0",
  ]
}
