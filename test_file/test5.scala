object test5
{
    // constant
    val n = 10

    def qq() {
        val n = 20
        println (n)
        return 
    }
    def main () {
        qq              // 20 
        println (n)     // 10
    }
}