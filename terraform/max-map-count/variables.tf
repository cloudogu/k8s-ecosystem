variable "node_selectors" {
  description = "A list of node selectors identifying nodes on which the daemonset is to be executed. The default value indicates that the daemonset will be executed on every node. Example: 'nodeType: db'"
  type = list(string)
  default = []
}