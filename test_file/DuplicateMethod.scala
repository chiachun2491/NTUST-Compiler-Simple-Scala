/*
 * Example with Functions
 */
object DuplicateMethod { 
    // constants 
    val a = 5
    
    // variables
    var c : int
    
    // function declaration
    def add (a: int, b: int) : int {
        return a+b 
    }

    // same name function declaration
    def add (b: int, c: int) : int {
        return b+c 
    }

    // main statements
    def main() {
        c = add(a, 10) 
        if (c > 10)
            print (-c) 
        else
            print (c)
        println ("Hello World")
    }
}