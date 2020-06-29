object test3
{
    // constants and variables
    var a: int
    var b: int
    var i: int
    var k: int
    val iii = 88
    val kkk = 99

    def add(a1: int, a2: int) : int {
        var ans: int
        val jjj = 99

        ans = a1 + a2
        a1 = iii
        a2 = jjj

        println (a1 + a2)   // 187

        return ans
    }

    def main () {
        println (add(10, 5) + 5)                    // 20
        println ((10 + 2 - 2) * 100 / 10)           // 100
        println (((10 + 2 - 2) * 100 / 10) % 9)     // 1
        println (-iii + kkk - 1)                    // 10
    }
}