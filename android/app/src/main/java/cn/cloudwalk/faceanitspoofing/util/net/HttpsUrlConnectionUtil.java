package cn.cloudwalk.faceanitspoofing.util.net;


import android.text.TextUtils;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import cn.cloudwalk.util.LoggerUtil;


/**
 * Https请求工具类
 */
public class HttpsUrlConnectionUtil {
    public static String post(String sUrl, String params) {
        return post(sUrl, params, "");
    }

    public static String post(String sUrl, String params, String contentType) {
        // 从上述SSLContext对象中得到SSLSocketFactory对象
        HttpsURLConnection conn = null;
        BufferedReader in = null;
        String result = "";
        OutputStream os = null;
        try {
            // 创建SSLContext对象，并使用我们指定的信任管理器初始化
            SSLContext sslContext = SSLContext.getInstance("TLS");
            sslContext.init(null, new TrustManager[]{new HttpsTrustManager()}, new SecureRandom());
            SSLSocketFactory ssf = sslContext.getSocketFactory();

            URL myURL = new URL(sUrl);

            HttpsURLConnection.setDefaultHostnameVerifier(new HostnameVerifier() {
                @Override
                public boolean verify(String arg0, SSLSession arg1) {
                    return true;
                }
            });
            conn = (HttpsURLConnection) myURL.openConnection();

            //设置加密协议
            conn.setSSLSocketFactory(ssf);
            conn.setDoOutput(true);
            conn.setDoInput(true);
            //设置请求方式
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Charset", "UTF-8");
            conn.setRequestProperty("Content-Type", TextUtils.isEmpty(contentType) ? "application/x-www-form-urlencoded" : contentType);

            //设置连接超时时长
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(15000);
            os = conn.getOutputStream();
            os.write(params.getBytes());
            os.close();

            int responseCode = conn.getResponseCode();
            /* 服务器返回的响应码 */
            if (responseCode == 200) {
                in = new BufferedReader(
                        new InputStreamReader(conn.getInputStream(), "UTF-8"));
                String retData;
                while ((retData = in.readLine()) != null) {
                    result += retData;
                }
            } else {
                LoggerUtil.i("https", "return error" + responseCode);
            }
        } catch (MalformedURLException ignored) {
        } catch (IOException ignored) {
        } catch (Exception ignored) {
        } finally {
            if (null != in) {
                try {
                    in.close();
                } catch (IOException ignored) {
                }
            }
            if (null != os) {
                try {
                    os.close();
                } catch (IOException ignored) {
                }
            }
            if (null != conn) {
                conn.disconnect();
            }
        }

        return result;
    }

    private static class HttpsTrustManager implements X509TrustManager {

        @Override
        public void checkClientTrusted(
                X509Certificate[] x509Certificates, String s)
                throws CertificateException {
        }

        @Override
        public void checkServerTrusted(
                X509Certificate[] x509Certificates, String s)
                throws CertificateException {
        }

        @Override
        public X509Certificate[] getAcceptedIssuers() {
            return new X509Certificate[]{};
        }
    }
}