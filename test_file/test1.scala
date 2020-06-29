object test1
{
    // constants
    val a = 5
    val t01 = true
    val t02 = "ssss""yyyy"

    // variables
    var c: int

    def add(a1: int, a2: int) : int {
        val a3 = 5
        var cc: int
        print (t02)
        cc = a1 - a2

        return a1 + a2
    }

    // main function
    def main() {
        print (t02)
        c = add(a, 10)

        if (c < 10)
            print (-c)

        if (c > 10)
            print (-c)
        else
            print (c)

        println ("Hello World")
    }
}