using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace SpecialEducationGames
{
    //All events must end with Event suffix

    public struct OnChoosableSelectedEvent
    {
        public Choosable Choosable;
    }

    public struct OnCorrectOneChoosedEvent
    {
        public Choosable Choosable;
    }

    public struct OnWrongOneChoosedEvent { }

    public struct OnStageCompletedEvent
    {
        public Choosable Choosable;
    }

    public struct OnShowInfoTextEvent
    {
        public ItemTuple ItemTuple;
        public string TextOnly;
    }

    public struct OnShowInfoTextAnimationCompletedEvent { }

    public struct OnGameFinishedEvent
    {
        
    }



    public struct OnVisualItemsCreatedEvent
    {
        public List<VisualItem> VisualItems;   
    }

    public struct OnChoosablesCreatedEvent
    {
        public List<Choosable> Choosables;
    }
}
