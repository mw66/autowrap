import ir


class CSharp(ir.IrVisitor):
    def __init__(self, out_file):
        self.out_file = out_file
        self.indent_level = 0

    def writeln(self, line):
        self.out_file.write(f"{self.indent_level * 4 * ' '}{line}\n")

    def open_block(self):
        self.writeln("{")
        self.indent_level += 1

    def close_block(self):
        self.indent_level -= 1
        self.writeln("}")

    def visit_Module(self, module):
        for node in module.nodes:
            self.visit(node)

    def visit_UnsupportedNode(self, node):
        self.writeln(
            f"// TODO: this node is not supported {node.ast_node}")

    def visit_Function(self, node):
        self.writeln(
            f"[Microsoft.VisualStudio.TestTools.UnitTesting.TestMethod]")
        self.writeln(f"public void {node.name}()")
        self.open_block()
        self.writeln("// TODO: generate function body")
        self.close_block()

    def translate(self, module):
        self.writeln("// this file is autogenerated, do not modify by hand")
        self.writeln('using Microsoft.VisualStudio.TestTools.UnitTesting;')

        # we use the fully-qualified names to avoid name-collisions
        # with the symbols from the test
        self.writeln(
            "[Microsoft.VisualStudio.TestTools.UnitTesting.TestClass]")
        self.writeln("public class TestMain")
        self.open_block()
        self.visit(module)
        self.close_block()


def translate(module, filename):
    with open(filename, "w") as file:
        CSharp(file).translate(module)
