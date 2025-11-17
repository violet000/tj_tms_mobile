package cn.cloudwalk.faceanitspoofing.util.net;

import android.os.AsyncTask;
import android.text.TextUtils;
import android.util.Base64;
import android.util.Log;

import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.UUID;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import cn.cloudwalk.util.Base64Util;
import cn.cloudwalk.util.FileUtil;
import cn.cloudwalk.util.LoggerUtil;
import cn.cloudwalk.util.TimeUtil;
import cn.cloudwalk.util.entity.AntiSpoofInfo;
import cn.cloudwalk.util.entity.RequestData;


/**
 * ClassName: OkHttpManager <br/>
 * Description:<br/>
 * date: 2016-5-10 11:55:20 <br/>
 *
 * @author 284891377
 * @since JDK 1.7
 */
public class HttpManager {
    private static final String TAG = HttpManager.class.getSimpleName();

    public static void postAsyncWithPublicCloud(final String url, final String params,
                                                final DataCallBack dataCallBack) {
        LoggerUtil.d(TAG, "--url&params:" + url + ", " + params);
        new AsyncTask<Object, Object, String>() {
            @Override
            protected String doInBackground(Object... param) {
                String result = null;
                try {
                    if (url.startsWith("https")) {
                        result = HttpsUrlConnectionUtil.post(url, params);
                    } else {
                        result = HttpUrlConnectionUtil.post(url, params);
                    }
                } catch (Exception e) {

                    e.printStackTrace();
                }
                return result;
            }

            protected void onPostExecute(String result) {
                try {
                    if (result != null && !result.isEmpty()) {
                        JSONObject jb = new JSONObject(result);
                        int resultCode = jb.optInt("code");
                        JSONObject obj = jb.getJSONObject("data");
                        int dataCode = obj.optInt("code");
                        if (resultCode == 0 && dataCode == 1) {
                            dataCallBack.requestSucess(jb);
                        } else {
                            String errorMsg = jb.optString("message");
                            dataCallBack.requestFailure("错误码: " + jb.optInt("code") + ", 错误信息: " +
                                    errorMsg);
                        }
                    } else {
                        dataCallBack.requestFailure("网络异常,请检查网络!");
                    }
                } catch (Exception e) {
                    dataCallBack.requestFailure("网络异常,请检查网络!");
                }

            }

        }.execute("");
    }

    public static void postAsyncWithAntiSpoofing(final String url, final String params,
                                                 final DataCallBack dataCallBack) {
        LoggerUtil.d(TAG, "--url&params:" + url + ", " + params);
        new AsyncTask<Object, Object, String>() {
            @Override
            protected String doInBackground(Object... param) {
                String result = null;
                try {
                    if (url.startsWith("https")) {
                        result = HttpsUrlConnectionUtil.post(url, params, "application/json");
                    } else {
                        result = HttpUrlConnectionUtil.post(url, params, "application/json");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
                return result;
            }

            protected void onPostExecute(String result) {
                try {
                    LoggerUtil.e("--result", result);
                    if (result != null && !result.isEmpty()) {
                        JSONObject jb = new JSONObject(result);
                        dataCallBack.requestSucess(jb);
                    } else {
                        dataCallBack.requestFailure("网络异常,请检查网络!");
                    }
                } catch (Exception e) {
                    dataCallBack.requestFailure("网络异常,请检查网络!");
                }

            }

        }.execute("");
    }

    public static void postAsync(final String url, final String params,
                                 final DataCallBack dataCallBack) {
        LoggerUtil.d(TAG, "--url&params:" + url + ", " + params);

        new AsyncTask<Object, Object, String>() {
            @Override
            protected String doInBackground(Object... param) {
                String result = null;
                try {
                    if (url.startsWith("https")) {
                        result = HttpsUrlConnectionUtil.post(url, params);
                    } else {
                        result = HttpUrlConnectionUtil.post(url, params);
                    }
                } catch (Exception ignored) {
                }
                return result;
            }

            protected void onPostExecute(String result) {
                try {
                    LoggerUtil.d(TAG, "--result:" + result);

                    JSONObject jb = new JSONObject(result);
                    if (jb.optInt("result") == 0) {
                        dataCallBack.requestSucess(jb);
                    } else {
                        dataCallBack.requestFailure(result);
                    }
                } catch (Exception e) {
                    dataCallBack.requestFailure("网络异常,请检查网络!");
                }

            }

        }.execute("");
    }

    public static void postAsyncWithIbis(final String url, final String params, String contentType,
                                         final IBISDataCallBack dataCallBack) {
        new AsyncTask<Object, Object, String>() {
            @Override
            protected String doInBackground(Object... param) {
                String result = null;
                try {
                    if (url.startsWith("https")) {
                        result = HttpsUrlConnectionUtil.post(url, params, contentType);
                    } else {
                        result = HttpUrlConnectionUtil.post(url, params, contentType);
                    }
                } catch (Exception ignored) {
                }
                return result;
            }

            protected void onPostExecute(String result) {

                try {
                    JSONObject jb = new JSONObject(result);
                    if (jb.optInt("code") == 1) {
                        dataCallBack.requestSuccess(jb.optString("result"));
                    } else {
                        dataCallBack.requestFailure(jb.optString("result"));
                    }
                } catch (Exception e) {
                    dataCallBack.requestFailure(result);
                }

            }

        }.execute("");
    }

    public static void cwIbisHuaxiaCreditCheckLiveness(String ipStr, String faceInfo, String keyIndex, String key, IBISDataCallBack dataCallBack) {
        try {
            Map<Object, Object> pairs = new HashMap<>();
            pairs.put("buscode", "checkLiveness");
            pairs.put("channel", "0300");
            pairs.put("engineCode", "cyface");
            pairs.put("orgCode", "0000");
            pairs.put("orgCodePath", "0000");
            pairs.put("tradingCode", "0601");
            pairs.put("tradingFlowNO", "30112155458198");
            pairs.put("verCode", "ver001");
            pairs.put("key", key);
            pairs.put("publicKey", Integer.parseInt(keyIndex));
            pairs.put("livenessDataEncrypt", faceInfo);
            pairs.put("tradingDate", TimeUtil.getNowString(new SimpleDateFormat("yyyyMMddHH")));
            pairs.put("tradingTime", System.currentTimeMillis());

            JSONObject obj = new JSONObject(pairs);
            postAsyncWithIbis(ipStr, obj.toString(), "application/json", dataCallBack);
        } catch (Exception e) {
            Log.e("cloudwalk ibis=", "" + e);
            e.printStackTrace();
        }
    }

    public static void cwIbisSM4CheckLiveness(String ipStr, String faceInfo, int encryptType, IBISDataCallBack dataCallBack) {
        try {
            Map<Object, Object> pairs = new HashMap<>();
            pairs.put("buscode", "checkLiveness");
            pairs.put("verCode", "ver001");
            pairs.put("engineCode", "cw001");
            pairs.put("orgCode", "cw001");
            pairs.put("channel", "cw001");
            pairs.put("tradingCode", "cw001");
            pairs.put("tradingFlowNO", "cw001");
            pairs.put("tradingDate", TimeUtil.getNowString(new SimpleDateFormat("yyyyMMddHH")));
            pairs.put("tradingTime", System.currentTimeMillis());
            pairs.put("equipmentNo", "cw001");
            pairs.put("organizationNo", "cw001");
            pairs.put("tellerNo", "cw001");
            pairs.put("bankcardNo", "cw001");
            pairs.put("livenessVersion", encryptType == 3 ? "v2" : "");
            pairs.put("livenessData", faceInfo);

            JSONObject obj = new JSONObject(pairs);
            postAsyncWithIbis(ipStr + "/checkLiveness", obj.toString(), "application/x-www-form-urlencoded", dataCallBack);
        } catch (Exception e) {
            Log.e("cloudwalk ibis=", "" + e);
            e.printStackTrace();
        }
    }

    /**
     * 公有云 活体-云之眼
     */
    public static void cwFaceSerLivessWithPublicCloud(String ipStr,
                                                      String app_key,
                                                      String app_secret,
                                                      String faceInfo,
                                                      DataCallBack dataCallBack) {
        Map<Object, Object> pairs = new HashMap<>();
        String nonceStr = "12345678";
        pairs.put("nonceStr", nonceStr);
        pairs.put("appKey", app_key);
        pairs.put("param", faceInfo);

        String sign = "";
        try {
            sign = createSign(app_secret, "/ai-cloud-face/liveness/action", pairs);
        } catch (Exception e) {
            e.printStackTrace();
        }
        pairs.put("sign", sign);
        JSONObject obj = new JSONObject(pairs);
        postAsyncWithPublicCloud(ipStr + "/ai-cloud-face/liveness/action", obj.toString(), dataCallBack);
    }

    /**
     * 公有云 活体-云之盾
     */
    public static void cwPublicCloudAntispoof(String ipStr,
                                              String app_key,
                                              String app_secret,
                                              String faceInfo,
                                              DataCallBack dataCallBack) {
        Map<Object, Object> pairs = new HashMap<>();
        String nonceStr = "12345678";
        pairs.put("nonceStr", nonceStr);
        pairs.put("appKey", app_key);
        pairs.put("param", faceInfo);

        String sign = "";
        try {
            sign = createSign(app_secret, "/ai-cloud-face/antispoof/action", pairs);
        } catch (Exception e) {
            e.printStackTrace();
        }
        pairs.put("sign", sign);
        JSONObject obj = new JSONObject(pairs);
        postAsyncWithPublicCloud(ipStr + "/ai-cloud-face/antispoof/action", obj.toString(), dataCallBack);
    }

    /****************** api ****************************/

    /**
     * 公有云 身份证
     */
    public static void cwIDOcrWithPublicCloud(String ipStr, String app_key, String app_secret, String imgBase64,
                                              int getFace,
                                              DataCallBack dataCallBack) {

        Map<Object, Object> pairs = new HashMap<>();
        pairs.put("appKey", app_key);
        pairs.put("nonceStr", "12345678");
        pairs.put("img", imgBase64);
        try {
            pairs.put("sign", createSign(app_secret, "/ai-cloud-face/ocr/bankcard", pairs));
        } catch (Exception exception) {
            exception.printStackTrace();
        }
        JSONObject obj = new JSONObject(pairs);
        postAsyncWithPublicCloud(ipStr + "/ai-cloud-face/ocr/bankcard", obj.toString(), dataCallBack);
    }

    /**
     * 公有云 银行卡
     */
    public static void cwBankOcrWithPublicCloud(String ipStr, String app_id, String app_secret,
                                                String imgAData, DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap<>();
        pairs.put("app_id", app_id);
        pairs.put("app_secret", app_secret);
        pairs.put("img", imgAData);

        postAsync(ipStr + "/ocr/bankcard", generateUrl(pairs), dataCallBack);
    }

    /**
     * FaceGo引擎 活体
     */
    public static void cwFaceSerLivessWithFaceGo(String ipStr, String app_id, String app_secret, String faceInfo, DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap();
        pairs.put("app_id", app_id);
        pairs.put("app_secret", app_secret);
        pairs.put("param", faceInfo);
        postAsync(ipStr + "/liveness/action", generateUrl(pairs), dataCallBack);
    }

    /**
     * 云之盾引擎 活体
     */
    public static void cwFaceSerLivessWithAntiSpoofing(String ipStr, String app_id, String app_secret, String faceInfo, DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap();
        pairs.put("app_id", app_id);
        pairs.put("app_secret", app_secret);
        pairs.put("param", faceInfo);
        postAsync(ipStr + "/antispoof/action", generateUrl(pairs), dataCallBack);
    }

    /**
     * 云之盾平台版token获取
     * 接口说明：用于获取访问开发者中心开放能力的身份令牌
     * URL: /sso/oauth/token
     * Method: POST
     * Content-Type: application/x-www-form-urlencoded
     */
    public static void cwPlatformToken(String ipStr, String clientId, String clientSecret, DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap();
        pairs.put("grant_type", "client_credentials");
        pairs.put("client_id", clientId);
        pairs.put("client_secret", clientSecret);
        
        String fullUrl = ipStr + "/sso/oauth/token";
        String params = generateUrl(pairs);
        
        LoggerUtil.e("========== Token请求详情 ==========");
        LoggerUtil.e("完整URL: " + fullUrl);
        LoggerUtil.e("请求参数: " + params);
        LoggerUtil.e("Content-Type: application/x-www-form-urlencoded");
        LoggerUtil.e("请求方式: POST");
        LoggerUtil.e("====================================");
        
        postAsyncForToken(fullUrl, params, dataCallBack);
    }

    /**
     * 专门用于token接口的POST请求方法
     * token接口响应格式：{"access_token": "...", "token_type": "...", "expires_in": ..., "scope": "...", "jti": "..."}
     * 成功判断：响应中包含access_token字段
     */
    private static void postAsyncForToken(final String url, final String params,
                                         final DataCallBack dataCallBack) {
        LoggerUtil.e(TAG, "========== 开始发送Token请求 ==========");
        LoggerUtil.e(TAG, "请求URL: " + url);
        LoggerUtil.e(TAG, "请求参数: " + params);
        LoggerUtil.e(TAG, "========================================");
        
        new AsyncTask<Object, Object, String>() {
            @Override
            protected String doInBackground(Object... param) {
                String result = null;
                try {
                    LoggerUtil.e(TAG, "开始执行网络请求...");
                    if (url.startsWith("https")) {
                        LoggerUtil.e(TAG, "使用HTTPS协议");
                        result = HttpsUrlConnectionUtil.post(url, params, "application/x-www-form-urlencoded");
                    } else {
                        LoggerUtil.e(TAG, "使用HTTP协议");
                        result = HttpUrlConnectionUtil.post(url, params, "application/x-www-form-urlencoded");
                    }
                    LoggerUtil.e(TAG, "网络请求完成，响应长度: " + (result != null ? result.length() : 0));
                } catch (Exception e) {
                    LoggerUtil.e(TAG, "网络请求异常: " + e.getMessage());
                    e.printStackTrace();
                }
                return result;
            }

            protected void onPostExecute(String result) {
                try {
                    LoggerUtil.e(TAG, "========== Token响应结果 ==========");
                    LoggerUtil.e(TAG, "原始响应: " + (result != null ? result : "null"));
                    LoggerUtil.e(TAG, "响应长度: " + (result != null ? result.length() : 0));
                    
                    if (result != null && !result.isEmpty()) {
                        JSONObject jb = new JSONObject(result);
                        LoggerUtil.e(TAG, "解析后的JSON: " + jb.toString());
                        
                        // token接口成功判断：响应中包含access_token字段
                        if (jb.has("access_token") && !TextUtils.isEmpty(jb.optString("access_token"))) {
                            LoggerUtil.e(TAG, "Token获取成功");
                            dataCallBack.requestSucess(jb);
                        } else {
                            // 如果响应中有error字段，说明是错误响应
                            String error = jb.optString("error", "");
                            String errorDescription = jb.optString("error_description", "");
                            String errorMsg = !TextUtils.isEmpty(errorDescription) ? errorDescription : 
                                            (!TextUtils.isEmpty(error) ? error : "Token获取失败");
                            
                            LoggerUtil.e(TAG, "Token获取失败 - error: " + error);
                            LoggerUtil.e(TAG, "Token获取失败 - error_description: " + errorDescription);
                            dataCallBack.requestFailure(errorMsg);
                        }
                    } else {
                        LoggerUtil.e(TAG, "响应为空或null");
                        dataCallBack.requestFailure("网络异常,请检查网络! 响应为空");
                    }
                    LoggerUtil.e(TAG, "====================================");
                } catch (Exception e) {
                    LoggerUtil.e(TAG, "========== Token请求解析异常 ==========");
                    LoggerUtil.e(TAG, "异常信息: " + e.getMessage());
                    LoggerUtil.e(TAG, "原始响应: " + result);
                    e.printStackTrace();
                    LoggerUtil.e(TAG, "==========================================");
                    dataCallBack.requestFailure("网络异常,请检查网络! 解析异常: " + e.getMessage());
                }
            }
        }.execute("");
    }

    /**
     * 云之盾平台版动作序列的获取（SDK初始化）
     * 接口说明：该接口用于云之盾SDK初始化使用
     * URL: /sdk/initialize
     * Method: POST
     * 请求参数：flowId, sceneId, bundleId（在body中）
     * URL参数：token, timestamp, nonce, sign（在URL中）
     */
    public static void cwPlatformActionSequence(String ipStr, RequestData requestData, DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap();
        pairs.put("flowId", requestData.getActionSequenceParams().getFlowId());
        pairs.put("sceneId", requestData.getActionSequenceParams().getSceneId());
        pairs.put("bundleId", requestData.getActionSequenceParams().getBundleId());

        Map<String, String> publicPairs = new HashMap();
        publicPairs.put("token", requestData.getPublicParams().getToken());
        publicPairs.put("timestamp", requestData.getPublicParams().getTimestamp());
        publicPairs.put("nonce", requestData.getPublicParams().getNonce());
        publicPairs.put("sign", requestData.getPublicParams().getSign());

        String params = "";
        try {
            JSONObject jsonParams = new JSONObject(pairs);
            params = jsonParams.toString();
        } catch (Exception e) {
            LoggerUtil.e(TAG, "构建请求参数异常: " + e.getMessage());
        }
        
        String fullUrl = ipStr + "/sdk/initialize?" + generateUrl(publicPairs);
        
        LoggerUtil.e(TAG, "========== SDK初始化请求详情 ==========");
        LoggerUtil.e(TAG, "完整URL: " + fullUrl);
        LoggerUtil.e(TAG, "请求Body: " + params);
        LoggerUtil.e(TAG, "Content-Type: application/json");
        LoggerUtil.e(TAG, "请求方式: POST");
        LoggerUtil.e(TAG, "========================================");
        
        postAsyncWithAntiSpoofing(fullUrl, params, dataCallBack);
    }

    /**
     * 云之盾平台版人脸核查（SDK活体场景）
     * 接口说明：该接口用于云之盾活体验证
     * URL: /anti/fraud/action
     * Method: POST
     */
    public static void cwPlatformAntiSpoof(String ipStr, RequestData requestData, DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap();
        pairs.put("channel", requestData.getAntiSpoofParams().getChannel());
        pairs.put("custLevel", requestData.getAntiSpoofParams().getCustLevel());
        pairs.put("custName", requestData.getAntiSpoofParams().getCustName());
        pairs.put("devicePrint", requestData.getAntiSpoofParams().getDevicePrint());
        pairs.put("deviceType", requestData.getAntiSpoofParams().getDeviceType());
        pairs.put("flowId", requestData.getAntiSpoofParams().getFlowId());
        pairs.put("locationInfo", requestData.getAntiSpoofParams().getLocationInfo());
        pairs.put("orgCode", requestData.getAntiSpoofParams().getOrgCode());
        pairs.put("param", requestData.getAntiSpoofParams().getParam());
        pairs.put("peopleId", requestData.getAntiSpoofParams().getPeopleId());
        pairs.put("sceneNo", requestData.getAntiSpoofParams().getSceneNo());
        pairs.put("sdkVersion", requestData.getAntiSpoofParams().getSdkVersion());
        pairs.put("sessionId", requestData.getAntiSpoofParams().getSessionId());
        pairs.put("tradingCode", requestData.getAntiSpoofParams().getTradingCode());
        pairs.put("filterType", "" + requestData.getAntiSpoofParams().getFilterType());
        pairs.put("timeStamp", "" + requestData.getAntiSpoofParams().getTimeStamp());
        if(null != requestData.getEncryptParams()) {
            pairs.put("workKey", "" + requestData.getEncryptParams().getEncWorkKey());
            pairs.put("publicIndex", "" + requestData.getEncryptParams().getPublicKeyIndex());
            pairs.put("sign", "" + requestData.getEncryptParams().getSign());
        }
        pairs.put("sdkErroFlag", "" + requestData.getAntiSpoofParams().getSdkErroFlag());
        Map<String, String> errorPairs = new HashMap();
        errorPairs.put("code", "" + requestData.getAntiSpoofParams().getSdkErroCode());
        errorPairs.put("message", "" + requestData.getAntiSpoofParams().getSdkErroMsg());

//        pairs.put("sdkErroObject", ""+new JSONObject(errorPairs));

        Map<String, String> publicPairs = new HashMap();
        publicPairs.put("token", requestData.getPublicParams().getToken());
        publicPairs.put("timestamp", requestData.getPublicParams().getTimestamp());
        publicPairs.put("nonce", requestData.getPublicParams().getNonce());
        publicPairs.put("sign", requestData.getPublicParams().getSign());

        String params = "";
        try {
            JSONObject jsonParams = new JSONObject(pairs);
            jsonParams.put("sdkErroObject", new JSONObject(errorPairs));
            params = jsonParams.toString();
        } catch (Exception e) {
            LoggerUtil.e(TAG, "构建活体检测请求参数异常: " + e.getMessage());
        }
        
        String fullUrl = ipStr + "/anti/fraud/action?" + generateUrl(publicPairs);
        
        LoggerUtil.e(TAG, "========== 活体检测请求详情 ==========");
        LoggerUtil.e(TAG, "完整URL: " + fullUrl);
        LoggerUtil.e(TAG, "请求Body: " + params);
        LoggerUtil.e(TAG, "Content-Type: application/json");
        LoggerUtil.e(TAG, "请求方式: POST");
        LoggerUtil.e(TAG, "========================================");
        
        // 保存请求参数到文件（如果locationInfo不为空）
        if (!TextUtils.isEmpty(requestData.getAntiSpoofParams().getLocationInfo())) {
            try {
                FileUtil.writeByteArrayToFile(params.getBytes(), requestData.getAntiSpoofParams().getLocationInfo());
            } catch (Exception e) {
                LoggerUtil.e(TAG, "保存请求参数到文件异常: " + e.getMessage());
            }
        }
        
        postAsyncWithAntiSpoofing(fullUrl, params, dataCallBack);
    }


    /**
     * IBIS AI反欺诈 活体
     */
    public static void cwFaceSerLivessWithIBISAntiSpoofing(String ipStr, String faceInfo, AntiSpoofInfo antiSpoofInfo, DataCallBack dataCallBack) {
        JSONObject pairs = new JSONObject();
        try {
            if (null != antiSpoofInfo) {
                if (TextUtils.isEmpty(antiSpoofInfo.getDeviceType())) {
                    dataCallBack.requestFailure("deviceType不能为空");
                    return;
                }
                if (TextUtils.isEmpty(antiSpoofInfo.getDeviceId())) {
                    dataCallBack.requestFailure("deviceId不能为空");
                    return;
                }
                if (TextUtils.isEmpty(antiSpoofInfo.getUserId())) {
                    dataCallBack.requestFailure("UserId不能为空");
                    return;
                }
                pairs.put("tempAuth", antiSpoofInfo.getTempAuth());
                pairs.put("userId", antiSpoofInfo.getUserId());
                pairs.put("deviceId", antiSpoofInfo.getDeviceId());
                pairs.put("deviceType", antiSpoofInfo.getDeviceType());
                pairs.put("phone", antiSpoofInfo.getPhone() + "");
                pairs.put("ip", antiSpoofInfo.getIp());
                pairs.put("lon", antiSpoofInfo.getLon() + "");
                pairs.put("lat", antiSpoofInfo.getLat() + "");
                pairs.put("address", antiSpoofInfo.getAddress());
                pairs.put("filterType", antiSpoofInfo.getFilterType() + "");
                pairs.put("eventNo", antiSpoofInfo.getEventNo());
                pairs.put("sceneNo", antiSpoofInfo.getSceneNo());
                pairs.put("actions", antiSpoofInfo.getActions());
                pairs.put("root", antiSpoofInfo.isRoot() + "");
            } else {
                dataCallBack.requestFailure("deviceType不能为空");
                return;
            }

            if (TextUtils.isEmpty(faceInfo)) {
                dataCallBack.requestFailure("防hack字串不能为空");
                return;
            }

            pairs.put("param", faceInfo);
            String uuid = UUID.randomUUID().toString().replaceAll("-", "");
            pairs.put("nonceStr", uuid);
            pairs.put("timeStamp", TimeUtil.getNowMills() + "");
        } catch (Exception ignored) {
            dataCallBack.requestFailure("参数有误，请检查参数");
            return;
        }
        postAsyncWithAntiSpoofing(ipStr + "/anti/antispoof/action", pairs.toString(), dataCallBack);
    }

    /**
     * 云之眼引擎 活体
     */
    public static void cwFaceSerLivess(String ipStr, String app_id, String app_secret, String faceInfo, DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap();
        pairs.put("app_id", app_id);
        pairs.put("app_secret", app_secret);
        pairs.put("param", faceInfo);
        postAsync(ipStr + "/faceliveness", generateUrl(pairs), dataCallBack);
    }

    /**
     * 云之眼 身份证OCR
     */
    public static void cwIDOcr(String ipStr, String app_id, String app_secret, String imgBase64,
                               int getFace,
                               DataCallBack dataCallBack) {
        try {
            Map<String, String> pairs = new HashMap<>();
            pairs.put("app_id", app_id);
            pairs.put("app_secret", app_secret);
            pairs.put("img", imgBase64);
            pairs.put("getFace", getFace + "");
            imgBase64 = null;
            postAsync(ipStr + "/ocr", generateUrl(pairs), dataCallBack);
        } catch (Exception e) {

            e.printStackTrace();
        }

    }

    /**
     * 南沙定制 活体
     */
    public static void cwFaceSerLivessWithNanSha(String ipStr, String app_id, String app_secret, String faceInfo, final DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap();
        pairs.put("app_id", app_id);
        pairs.put("app_secret", app_secret);
        pairs.put("img", faceInfo);
        final String url = ipStr + "/liveness/silence/image";
        final String params = generateUrl(pairs);

        postAsync(url, params, dataCallBack);
//        LoggerUtil.d(TAG, "--url&params:" + url + ", " + params);
//        new AsyncTask<Object, Object, String>() {
//            @Override
//            protected String doInBackground(Object... param) {
//                String result = null;
//                try {
//                    if (url.startsWith("https")) {
//                        result = HttpsUrlConnectionUtil.post(url, params);
//                    } else {
//                        result = HttpUrlConnectionUtil.post(url, params);
//                    }
//                } catch (Exception ignored) {
//                }
//                return result;
//            }
//
//            protected void onPostExecute(String result) {
//                try {
//                    LoggerUtil.d(TAG, "--result:" + result);
//
//                    JSONObject jb = new JSONObject(result);
//                    if (jb.optInt("result") == 0) {
//                        dataCallBack.requestSucess(jb);
//                    } else {
//                        dataCallBack.requestFailure(jb.toString());
//                    }
//                } catch (Exception e) {
//                    dataCallBack.requestFailure("网络异常,请检查网络!");
//                }
//
//            }
//
//        }.execute("");
    }

    public static void cwCheckWatermark(String ipStr,
                                        String app_id,
                                        String app_secret,
                                        String imgBase64,
                                        String hiddenWatermark,
                                        DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap();
        pairs.put("app_id", app_id);
        pairs.put("app_secret", app_secret);
        pairs.put("imgSrc", imgBase64);
        pairs.put("strMask", hiddenWatermark);
        postAsync(ipStr + "/tool/digitalwater/detectString", generateUrl(pairs), dataCallBack);

    }

    /**
     * ibis 银行卡ocr
     */
    public static void cwBankOcr(String ipStr, String app_id, String app_secret,
                                 String imgAData, DataCallBack dataCallBack) {
        Map<String, String> pairs = new HashMap<>();
        pairs.put("app_id", app_id);
        pairs.put("app_secret", app_secret);
        pairs.put("img", imgAData);

        postAsync(ipStr + "/ocr/bankcard", generateUrl(pairs), dataCallBack);
    }

    private static String createSign(String secret, String uri, Map<Object, Object> parameters) throws Exception {
        SortedMap<Object, Object> parametersForSign = new TreeMap<>();
        parametersForSign.put("uri", uri);
        parametersForSign.putAll(parameters);
        StringBuilder sb = new StringBuilder();
        Set es = parametersForSign.entrySet();
        Iterator it = es.iterator();
        while (it.hasNext()) {
            Map.Entry entry = (Map.Entry) it.next();
            String k = (String) entry.getKey();
            Object v = entry.getValue();
            if (null != v && !"".equals(v)
                    && !"sign".equals(k) && !"key".equals(k)) {
                if (!it.hasNext()) {
                    sb.append(k).append("=").append(v);
                } else {
                    sb.append(k).append("=").append(v).append("&");
                }
            }
        }
        Mac mac = Mac.getInstance("HmacSHA1");
        SecretKeySpec secretKey = new SecretKeySpec(secret.getBytes("UTF-8"), mac.getAlgorithm());
        mac.init(secretKey);
        byte[] hash = mac.doFinal(sb.toString().getBytes("UTF-8"));
        return Base64Util.encode(hash, Base64.NO_WRAP);
    }

    /**
     * 根据基础url和参数拼接请求地址
     */
    private static String generateUrl(Map<String, String> params) {
        StringBuilder urlBuilder = new StringBuilder("");
        if (null != params) {
            Iterator<Map.Entry<String, String>> iterator = params.entrySet().iterator();
            while (iterator.hasNext()) {
                Map.Entry<String, String> param = iterator.next();
                String key = param.getKey();
                String value = param.getValue();
                if (TextUtils.isEmpty(value)) {
                    continue;
                }
                try {
                    urlBuilder.append(key).append('=').append(URLEncoder.encode(value, "UTF-8"));
                } catch (UnsupportedEncodingException e) {
                    urlBuilder.append(key).append('=').append(value);
                    e.printStackTrace();
                }
                if (iterator.hasNext()) {
                    urlBuilder.append('&');
                }
            }
        }
        return urlBuilder.toString();
    }

    /****************** 数据回掉接口 ****************************/
    public interface DataCallBack {
        void requestFailure(String errorMsg);

        void requestSucess(JSONObject jb);
    }

    public interface IBISDataCallBack {
        void requestFailure(String errorMsg);

        void requestSuccess(String successMsg);
    }

}
