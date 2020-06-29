object test6
{
    // constant and variables
    val n = 9
    var i: int
    var j: int

    def main () {
        i = 1
        j = 1

        while (i <= n) {
            j = 1
            
            while (j <= n) {
                print (i)
                print (" * ")
                print (j)
                print (" = ")
                println (i * j)

                j = j + 1
            }

            println ("----------")

            /*
                hello
                hello??
                helloooooooo!
            */

            i = i + 1
        }
    }
}