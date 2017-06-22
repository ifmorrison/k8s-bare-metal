data "template_file" "certificates" {
  template = "${file("${path.module}/templates/kubernetes-csr.json")}"
  depends_on = [
    "triton_machine.controller",
    "triton_machine.worker",
    "triton_machine.edge_worker"
  ]

  vars {
    controller_ips = "${join(",", formatlist("\"%s\"", triton_machine.controller.ips))}"
    worker_ips = "${join(",", formatlist("\"%s\"", triton_machine.worker.ips))}"
    edge_worker_ips = "${join(",", formatlist("\"%s\"", triton_machine.edge_worker.ips))}"
    etcd_ips = "\"${var.etcd1_ip}\",\"${var.etcd2_ip}\",\"${var.etcd3_ip}\""
  }
}

resource "null_resource" "certificates" {
  triggers {
    template_rendered = "${data.template_file.certificates.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.certificates.rendered}' > cert/kubernetes-csr.json"
  }

  provisioner "local-exec" {
    command = "cd cert; cfssl gencert -initca ca-csr.json | cfssljson -bare ca; cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes"
  }
}
