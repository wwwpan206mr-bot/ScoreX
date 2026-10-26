package com.scorex.app.scorex

import java.io.File
import java.net.URI
import java.security.MessageDigest

internal object UpdatePolicy {
    const val MAX_BYTES = 250L * 1024 * 1024
    fun trustedUrl(text: String): Boolean = runCatching {
        val uri = URI(text)
        uri.scheme == "https" && uri.host == "github.com" && uri.port == -1 &&
            uri.userInfo == null && uri.query == null && uri.fragment == null &&
            Regex("^/wwwpan206mr-bot/ScoreX/releases/download/[^/]+/[^/]+\\.apk$").matches(uri.path) &&
            uri.path.split('/').none { it == "." || it == ".." }
    }.getOrDefault(false)
    fun compatible(name: String?, installedName: String, code: Long, installedCode: Long,
                   signers: Set<String>, installedSigners: Set<String>) =
        name == installedName && code > installedCode && signers.isNotEmpty() && signers == installedSigners
    fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { input ->
            val buffer = ByteArray(128 * 1024)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }
}
