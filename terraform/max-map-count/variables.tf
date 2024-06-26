variable "node_selectors" {
  description = "A map of node selectors identifying nodes on which the daemonset is to be executed. The default value indicates that the daemonset will be executed on every node. Example: 'nodeType: db'"
  type = map(string)
  default = {}
}