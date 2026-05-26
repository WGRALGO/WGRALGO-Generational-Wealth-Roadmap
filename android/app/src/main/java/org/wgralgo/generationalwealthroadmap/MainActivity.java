package org.wgralgo.generationalwealthroadmap;

import android.graphics.Color;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
  @Override
  public void onStart() {
    super.onStart();
    if (bridge != null && bridge.getWebView() != null) {
      bridge.getWebView().setBackgroundColor(Color.BLACK);
    }
  }
}
