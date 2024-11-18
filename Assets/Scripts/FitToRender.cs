using UnityEngine;

public class FitToRender : MonoBehaviour
{
    [SerializeField]
    protected Camera curCamera;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        curCamera = gameObject.GetComponentInParent<Camera>();

        //better camera frustum handling
        Vector3[] frustum = new Vector3[4];

        //must have made it manually
        //because function provided by Unity works only for perspective view AND does not mentions it in documentation!
        Debug.Log(curCamera);
        frustum[0] = new Vector3(-curCamera.orthographicSize * curCamera.aspect, -curCamera.orthographicSize, curCamera.nearClipPlane);
        frustum[1] = new Vector3(-frustum[0].x, frustum[0].y, curCamera.nearClipPlane);
        frustum[2] = new Vector3(frustum[0].x, -frustum[0].y, curCamera.nearClipPlane);
        frustum[3] = new Vector3(-frustum[0].x, -frustum[0].y, curCamera.nearClipPlane);
        //curCamera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), curCamera.nearClipPlane, Camera.MonoOrStereoscopicEye.Mono, frustum);
        //local frustum to global conversion
        for (int i = 0; i < 4; ++i)
        {
            frustum[i] = curCamera.transform.TransformPoint(frustum[i]);
        }

        //actual object fitting
        gameObject.transform.localScale = new Vector3(Vector3.Distance(frustum[0], frustum[1]), Vector3.Distance(frustum[0], frustum[2]), 1);
    }

    // Update is called once per frame
    void Update()
    {

    }
}
