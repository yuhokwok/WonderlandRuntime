//
//  BlockRunnerList.swift
//  FBPLand
//
//  Created by Reality Builder Team on 3/3/2022.
//

import UIKit

extension BlockRunner {

    static let classRepo : [BlockRunner.Type] = [
        //input
        ConstantBlock.self,
        StringBlock.self,
        ObjectCollisionBlock.self,
        TapOnScreenBlock.self,
        DoubleTapOnScreenBlock.self,
        TouchAtLocationBlock.self,
        TapOnObjectBlock.self,
        WhenGameStartBlock.self,
        ScheduleActionBlock.self,
        BodyAnchorBlock.self,
        ObjectBreakBlock.self,
        
        //middle
        CalculatorBlock.self,
        ComparisonBlock.self,
        LogicBlock.self,
        CounterBlock.self,
        AdjustTimeBlock.self,
        RandomPositionBlock.self,
        TrueBlock.self,
        FalseBlock.self,
        WaitBlock.self,
        
        //output
        BGMBlock.self,
        EventSoundBlock.self,
        ShootBallBlock.self,
        LabelOnScreenBlock.self,
        TimerOnScreenBlock.self,
        DebugBlock.self,
        DestroyObjectBlock.self,
        AddForceBlock.self,
        MoveBlock.self,
        RotateBlock.self,
        OrbitBlock.self,
        RealTimeAddOnBlock.self,
        NextSceneBlock.self, 
        GoToSceneBlock.self,
        FixedBlock.self,
        KinematicsBlock.self,
        DynamicBlock.self,

        //object
        USDZObjectBlock.self,
        PrimitiveObjectBlock.self,
        TextObjectBlock.self
    ]
}
