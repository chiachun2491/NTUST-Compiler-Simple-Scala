object test2
{
    // constants and variables
    var a: int
    var b: int
    var i: int
    var k: int
    val iii = 88

    def add(a1: int, a2: int) : int {
        var ans: int
        val jjj = 99

        ans = a1 + a2
        a1 = iii
        a2 = jjj

        return ans
    }

    def add2(a1: int, a2: int) : int {
        return add(a1, a2)
    }

    def main () {

        println (add2(10, 10))  // 20
        
        k = 0 
        i = 5
        k = add(25 + 100 - 5 * i, k)

        println (k)   // 100
        println (i)   // 5
        
        a = 8
        b = 7

        if (a > b || a < b) 
            a = a * b
        else 
            a = a + b
        
        println (a)     // 56
        println (b)     // 7

        a = 5
        b = 5
        
        if (a != b) 
            a = a * b
        else 
            a = a + b
        
        println (a)     // 10
        println (b)     // 5

        if (!(!(a == b))) 
            println ("Hello Hello")
    }
}