object test7
{
    // constant and variables
    var i: int
    var j: int

    def main () {
        for (i <- 1 to 9) {
            for (j <- 1 to 9) {
                print (i)
                print (" * ")
                print (j)
                print (" = ")
                println (i * j)
            }

            println ("----------")

            /*
                hello
                hello??
                helloooooooo!
            */
        }
    }
}