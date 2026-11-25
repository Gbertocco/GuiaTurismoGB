package com.example.guia_turismo

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null
    private var listener: LocationListener? = null
    private lateinit var locations: LocationManager
    private val requestCode = 7301

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        locations = getSystemService(LOCATION_SERVICE) as LocationManager
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.example.guia_turismo/dispositivo").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "diretorioDocumentos" -> result.success(filesDir.absolutePath)
                    "obterPosicao" -> {
                        if (pending != null) {
                            result.error("OCUPADO", "Uma busca de GPS já está em andamento.", null)
                        } else {
                            pending = result
                            if (hasLocationPermission()) locate()
                            else if (call.argument<Boolean>("solicitarPermissao") == true) {
                                requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION,
                                    Manifest.permission.ACCESS_COARSE_LOCATION), requestCode)
                            } else fail("PERMISSAO_NEGADA", "Permita o acesso à localização.")
                        }
                    }
                    "configuracoesGps" -> {
                        startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                        result.success(null)
                    }
                    "configuracoesApp" -> {
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "abrirUrl" -> {
                        val uri = Uri.parse(call.argument<String>("url") ?: "")
                        val hosts = setOf("www.google.com", "maps.google.com", "www.openstreetmap.org")
                        if (uri.scheme != "https" || uri.host !in hosts) {
                            result.error("URL_INVALIDA", "Endereço de navegação inválido.", null)
                        } else {
                            startActivity(Intent(Intent.ACTION_VIEW, uri))
                            result.success(null)
                        }
                    }
                    "compartilhar" -> {
                        val text = call.argument<String>("texto") ?: ""
                        if (text.isBlank()) result.error("TEXTO_VAZIO", "Não há conteúdo para compartilhar.", null)
                        else {
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, text)
                                putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("titulo"))
                            }
                            startActivity(Intent.createChooser(intent, null))
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (_: ActivityNotFoundException) {
                result.error("SEM_APLICATIVO", "Não há aplicativo disponível para esta ação.", null)
            } catch (_: SecurityException) {
                if (call.method == "obterPosicao") fail("PERMISSAO_NEGADA", "Permita o acesso à localização.")
                else result.error("SEM_PERMISSAO", "O Android não permitiu esta ação.", null)
            } catch (_: Exception) {
                if (call.method == "obterPosicao") fail("GPS_ERRO", "Não foi possível obter o GPS.")
                else result.error("DISPOSITIVO_ERRO", "Não foi possível concluir esta ação.", null)
            }
        }
    }

    private fun hasLocationPermission(): Boolean =
        checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
        checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grants: IntArray) {
        super.onRequestPermissionsResult(code, permissions, grants)
        if (code != requestCode || pending == null) return
        if (hasLocationPermission()) locate()
        else {
            val blocked = !shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_COARSE_LOCATION) &&
                !shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_FINE_LOCATION)
            fail(if (blocked) "PERMISSAO_BLOQUEADA" else "PERMISSAO_NEGADA", "O acesso ao GPS foi negado.")
        }
    }

    @Suppress("MissingPermission", "DEPRECATION")
    private fun locate() {
        if (!hasLocationPermission()) { fail("PERMISSAO_NEGADA", "Permita o acesso à localização."); return }
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter { locations.allProviders.contains(it) && locations.isProviderEnabled(it) }
        if (providers.isEmpty()) { fail("GPS_DESLIGADO", "Ative a localização do aparelho."); return }
        val cached = providers.mapNotNull { provider ->
            try { locations.getLastKnownLocation(provider) } catch (_: SecurityException) { null }
        }.filter { System.currentTimeMillis() - it.time in 0..60000 }.maxByOrNull { it.time }
        if (cached != null) { finish(cached); return }
        val callback = object : LocationListener {
            override fun onLocationChanged(location: Location) { finish(location) }
            override fun onProviderEnabled(provider: String) {}
            override fun onProviderDisabled(provider: String) {
                if (providers.none { locations.isProviderEnabled(it) }) fail("GPS_DESLIGADO", "Ative a localização do aparelho.")
            }
            @Deprecated("Android legacy callback")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        }
        listener = callback
        var registered = false
        providers.forEach { provider ->
            try {
                locations.requestLocationUpdates(provider, 0L, 0f, callback, Looper.getMainLooper())
                registered = true
            } catch (_: SecurityException) { /* Tenta o provedor que aceita a permissão aproximada. */ }
        }
        if (!registered) { fail("PERMISSAO_NEGADA", "Permita o acesso à localização."); return }
        handler.postDelayed({ fail("GPS_TIMEOUT", "O GPS demorou para responder.") }, 25000)
    }

    private fun finish(location: Location) {
        val result = pending ?: return
        pending = null
        clearListener()
        result.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude,
            "accuracy" to location.accuracy.toDouble(), "timestamp" to location.time))
    }
    private fun fail(code: String, message: String) {
        val result = pending ?: return
        pending = null
        clearListener()
        result.error(code, message, null)
    }
    private fun clearListener() {
        handler.removeCallbacksAndMessages(null)
        listener?.let { try { locations.removeUpdates(it) } catch (_: Exception) {} }
        listener = null
    }
    override fun onStop() {
        if (listener != null) fail("CANCELADO", "Busca de localização pausada.")
        super.onStop()
    }
    override fun onDestroy() {
        if (pending != null) fail("CANCELADO", "Aplicativo encerrado.")
        clearListener()
        super.onDestroy()
    }
}
