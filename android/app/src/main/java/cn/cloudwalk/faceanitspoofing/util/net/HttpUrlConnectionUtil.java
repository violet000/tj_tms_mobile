package cn.cloudwalk.faceanitspoofing.util.net;


import android.text.TextUtils;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import cn.cloudwalk.util.LoggerUtil;


/**
 * HttpUrlConnection联网
 */
public class HttpUrlConnectionUtil {
    public static String post(String sUrl, String params) {
        return post(sUrl, params, "");
    }

    // Post方式请求
    public static String post(String sUrl, String params, String contentType) {
        String result = "";
        BufferedReader in = null;
        OutputStream os = null;
        HttpURLConnection urlConn = null;
        try {
            // 请求的参数转换为byte数组
            byte[] postData = params.getBytes();
            URL url = new URL(sUrl);
            urlConn = (HttpURLConnection) url.openConnection();
            urlConn.setConnectTimeout(10 * 1000);
            urlConn.setReadTimeout(15 * 1000);
            // Post请求必须设置允许输出
            urlConn.setDoOutput(true);
            // 发送POST请求必须设置允许输入
            urlConn.setDoInput(true);
            // 设置请求的头
            urlConn.setRequestProperty("Connection", "keep-alive");
            // 设置请求的头
            urlConn.setRequestProperty("Content-Type", TextUtils.isEmpty(contentType) ? "application/x-www-form-urlencoded" : contentType);

            // 设置请求的头
//			urlConn.setRequestProperty("Content-Type", "application/json");
            // 设置请求的头

            // Post请求不能使用缓存
            urlConn.setUseCaches(false);
            // 设置为Post请求
            urlConn.setRequestMethod("POST");
            urlConn.setInstanceFollowRedirects(true);
            // 开始连接
            // urlConn.connect();
            // 发送请求参数
            // DataOutputStream dos = new DataOutputStream(urlConn.getOutputStream());
            // dos.write(postData);
            // dos.flush();
            // dos.close();
            os = urlConn.getOutputStream();
            os.write(postData);
            os.flush();
            int responseCode = urlConn.getResponseCode();
            // 判断请求是否成功
            if (responseCode == 200) {
                // 获取返回的数据
                in = new BufferedReader(new InputStreamReader(urlConn.getInputStream(), "UTF-8"));
                String inputLine = "";
                while ((inputLine = in.readLine()) != null) {
                    result += inputLine;
                }
            } else {
                LoggerUtil.i("http", "return error code:" + responseCode + ", error msg:" + urlConn.getResponseMessage());
            }

        } catch (Exception ignored) {
            ignored.printStackTrace();

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

            if (null != urlConn) {
                urlConn.disconnect();
            }
        }

        return result;
    }


}
