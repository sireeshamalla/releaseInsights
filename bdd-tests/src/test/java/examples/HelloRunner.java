// File: bdd-tests/src/test/java/examples/HelloRunner.java
package examples;

import com.intuit.karate.junit5.Karate;

class HelloRunner {
    @Karate.Test
    Karate testHello() {
        return Karate.run("hello").relativeTo(getClass());
    }
}