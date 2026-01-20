package com.qimi.heatlink

import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.TextView
import android.app.Activity

class SplashActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.splash_screen)
        
        // 设置 QIMI 文字：weight 700，QIMI的bottom距离HeatLink的top间距75dp
        val qimiText = findViewById<TextView>(R.id.qimi_text)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            qimiText?.setTypeface(Typeface.create(null, 700, false))
        } else {
            qimiText?.setTypeface(null, Typeface.BOLD) // BOLD = 700
        }
        
        // 设置 HeatLink 文字：weight 510
        val heatlinkText = findViewById<TextView>(R.id.heatlink_text)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            heatlinkText?.setTypeface(Typeface.create(null, 510, false))
        } else {
            // API 28 以下使用 MEDIUM (500) 作为近似值
            heatlinkText?.setTypeface(null, Typeface.NORMAL)
        }
        
        // 等待布局完成后再计算位置
        qimiText?.post {
            val density = resources.displayMetrics.density
            val heatlinkHeight = heatlinkText?.height ?: (50 * density).toInt()
            val qimiHeight = qimiText?.height ?: (60 * density).toInt()
            // QIMI的bottom距离HeatLink的top间距75dp
            // translationY = -(HeatLink高度/2 + 75dp + QIMI高度/2)
            val translationY = -(heatlinkHeight / 2.0 + 75 * density + qimiHeight / 2.0)
            qimiText?.translationY = translationY.toFloat()
        }
        
        // 延迟2秒后跳转到 MainActivity
        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(this, MainActivity::class.java)
            startActivity(intent)
            finish()
        }, 2000)
    }
}
