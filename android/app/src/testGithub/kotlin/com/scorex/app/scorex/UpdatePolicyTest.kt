package com.scorex.app.scorex

import org.junit.Assert.*
import org.junit.Test
import java.io.File

class UpdatePolicyTest {
    @Test fun `only direct assets from the ScoreX release repository are accepted`() {
        assertTrue(UpdatePolicy.trustedUrl("https://github.com/wwwpan206mr-bot/ScoreX/releases/download/v1.0.8/scorex-arm64.apk"))
        listOf("http://github.com/wwwpan206mr-bot/ScoreX/releases/download/v1/a.apk",
            "https://github.com/other/ScoreX/releases/download/v1/a.apk",
            "https://github.com/wwwpan206mr-bot/ScoreX/actions/artifacts/1",
            "https://github.com/wwwpan206mr-bot/ScoreX/releases/download/v1/a.zip",
            "https://github.com@evil.test/wwwpan206mr-bot/ScoreX/releases/download/v1/a.apk",
            "https://github.com/wwwpan206mr-bot/ScoreX/releases/download/../a.apk")
            .forEach { assertFalse(it, UpdatePolicy.trustedUrl(it)) }
    }
    @Test fun `an update must match package and signing identity and have a higher code`() {
        val name = "com.scorex.app.scorex"
        assertTrue(UpdatePolicy.compatible(name, name, 12, 11, setOf("key"), setOf("key")))
        assertFalse(UpdatePolicy.compatible(name, name, 11, 11, setOf("key"), setOf("key")))
        assertFalse(UpdatePolicy.compatible("other", name, 12, 11, setOf("key"), setOf("key")))
        assertFalse(UpdatePolicy.compatible(name, name, 12, 11, setOf("new-key"), setOf("key")))
        assertFalse(UpdatePolicy.compatible(name, name, 12, 11, emptySet(), emptySet()))
    }
    @Test fun `checksum reflects file contents`() {
        val file = File.createTempFile("scorex-update", ".apk")
        try {
            file.writeText("abc")
            assertEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", UpdatePolicy.sha256(file))
            file.appendText("corrupt")
            assertNotEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", UpdatePolicy.sha256(file))
        } finally { file.delete() }
    }
}
