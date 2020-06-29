object test4
{
    // constants and variables
    var a: int
    var b: int
    var i: int
    var k: int
    
    val n = 10
    var sum: int
    var index: int

    def main () {
        a = 5
        b = 5

        if (!(!(a == b))) 
            println ("a == b")
        
        if (!(!(a == b))) 
            println ("a == b")
        else 
            println ("a != b")

        if (!((a == b))) 
            println ("a != b")
        
        /* ***************** */ 

        sum = 0
        index = 0

        while (index <= n) {
            sum = sum + index

            if (index == 5) 
                println ("index == 5 !!!!") 

            index = index + 1
        }

        print ("The sum is ")
        println (sum)

        /* ***************** */ 

        a = 5
        b = 6

        if (!(!(a == b))) 
            println ("a == b")
        
        if (!(!(a == b))) 
            println ("a == b")
        else 
            println ("a != b")

        if (!((a == b))) 
            println ("a != b")

        /* ***************** */

        sum = 0
        index = 0

        while (index <= n) {
            sum = sum + index

            if (index != 5) {
                print ("index != 5 !!!!") 
                println (index)
            }
            else {
                println ("index == 5 !!!!")
            }
            
            index = index + 1
        }

        print ("The sum is ")
        println (sum)
    }
}