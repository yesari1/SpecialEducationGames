using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Security;
using UnityEditor;
using UnityEngine;
using Zenject;

public class ParticleManager : MonoBehaviour
{
    private static ParticleManager _instance;

    private Canvas _canvas;

    public static ParticleManager Instance => _instance;

    [Inject]
    public void Construct(Canvas canvas)
    {
        _canvas = canvas;
    }

    private void Awake()
    {
        if(_instance == null)
            _instance = this;
    }

    //Zaten sahnede olanı oynatıyoruz
    public void Play(ParticleSystem particle, bool loop)
    {
        if (particle != null)
        {
            particle.gameObject.SetActive(true);
            ParticleSystem.MainModule main = particle.main;

            main.loop = loop;
            main.stopAction = ParticleSystemStopAction.Destroy;
            particle.Play();
        }
    }


    public void Play(ParticleSystem particle, bool loop,Vector3 pos)
    {
        if (particle != null)
        {
            particle.gameObject.SetActive(true);
            particle.gameObject.transform.position = pos;
            ParticleSystem.MainModule main = particle.main;

            main.loop = loop;
            main.stopAction = ParticleSystemStopAction.Destroy;
            particle.Play();
        }
    }


    public void Stop(ParticleSystem particle,bool destroy)
    {
        ParticleSystem.MainModule main = particle.main;

        if(destroy)
            main.stopAction = ParticleSystemStopAction.Destroy;
        else
            main.stopAction = ParticleSystemStopAction.None;

        particle.Stop();
    }

    //Yeni obje oluşturup pozisyon verip başlatıyoruz
    public ParticleSystem CreateAndPlay(ParticleSystem particle,Vector2 position,bool loop,bool canvasParent = true)
    {
        ParticleSystem newParticle = null;
        //Eğer particle atanmışsa
        if (particle != null)
        {
            if(!canvasParent) newParticle = Instantiate(particle);
            else newParticle = Instantiate(particle, _canvas.transform);

            newParticle.gameObject.SetActive(true);

            ParticleSystem.MainModule main = newParticle.main;
            main.loop = loop;
            //main.stopAction = ParticleSystemStopAction.Destroy;

            newParticle.GetComponent<RectTransform>().anchoredPosition = position;

            newParticle.Play();
        }
        return newParticle;
    }

    public GameObject CreateAndPlayRandom(List<ParticleSystem> particles, GameObject parent, Vector3 position, bool loop)
    {
        int rand = Random.Range(0, particles.Count);
        GameObject returnPart = null;
        //Eğer particle atanmışsa
        if (particles[rand] != null)
        {
            ParticleSystem newParticle;
            if (parent == null) newParticle = Instantiate(particles[rand]);
            else newParticle = Instantiate(particles[rand], parent.transform);

            newParticle.gameObject.SetActive(true);

            ParticleSystem.MainModule main = newParticle.main;
            main.loop = loop;
            //main.stopAction = ParticleSystemStopAction.Destroy;

            newParticle.gameObject.transform.position = position;

            newParticle.Play();
            returnPart = newParticle.gameObject;
        }
        else
            Debug.LogWarning("Particle list element is null. Element: " + rand);
        
        return returnPart;
    }

    //Belirli bir süree sonra oynatıyoruz
    public IEnumerator CreateAndPlay(ParticleSystem particle, GameObject parent, Vector3 position, bool loop,float time)
    {
        yield return new WaitForSeconds(time);
        //Eğer particle atanmışsa
        if (particle != null)
        {
            ParticleSystem newParticle = Instantiate(particle, parent.transform);
            newParticle.gameObject.SetActive(true);

            ParticleSystem.MainModule main = newParticle.main;
            main.loop = loop;
            main.stopAction = ParticleSystemStopAction.Destroy;

            newParticle.GetComponent<RectTransform>().anchoredPosition = position;

            newParticle.Play();
        }
    }

}



