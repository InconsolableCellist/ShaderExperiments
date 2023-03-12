using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveSphere : MonoBehaviour
{
    public GameObject collider; 
    void Start() {
        
    }

    void Update() {
        transform.position = new Vector3(Mathf.PingPong(Time.time, 10) - 5, 0, Mathf.PingPong(Time.time, 10) - 5);
    }
}
