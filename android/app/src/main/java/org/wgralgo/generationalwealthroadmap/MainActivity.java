package org.wgralgo.generationalwealthroadmap;

import android.app.AlertDialog;
import android.webkit.WebView;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {

    /**
     * Hardware back button:
     *  - first asks the web app to handle it (close a menu sheet, or go back
     *    to the start screen from a round or the results);
     *  - if the web app is already on the start screen, confirm before exit.
     */
    @Override
    public void onBackPressed() {
        WebView webView = getBridge() != null ? getBridge().getWebView() : null;
        if (webView == null) {
            super.onBackPressed();
            return;
        }
        webView.evaluateJavascript(
                "(window.onAndroidBack && window.onAndroidBack())",
                value -> {
                    if ("true".equals(value)) {
                        return; // handled inside the app
                    }
                    new AlertDialog.Builder(MainActivity.this)
                            .setTitle("Exit Generational Wealth Roadmap?")
                            .setMessage("Leave the app?")
                            .setPositiveButton("Exit", (d, w) -> finish())
                            .setNegativeButton("Stay", null)
                            .show();
                });
    }
}
