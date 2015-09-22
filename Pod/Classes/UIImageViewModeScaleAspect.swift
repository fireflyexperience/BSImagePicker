//
//  UIImageViewModeScaleAspect.m
//
// http://www.viviencormier.fr/
//
//  Created by Vivien Cormier on 02/05/13.
//  Copyright (c) 2013 Vivien Cormier. All rights reserved.
//

import UIKit

class UIImageViewModeScaleAspect: UIView {
    var image: UIImage? {
        get {
            return self.img?.image
        }
        set {
            self.img?.image = newValue
        }
    }
    
    var newFrameWrapper: CGRect?
    var newFrameImg: CGRect?
    
    private var img: UIImageView?
    
    override var contentMode: UIViewContentMode {
        get {
            if let img = self.img {
                return img.contentMode
            } else {
                return super.contentMode
            }
        }
        set {
            if let img = self.img {
                img.contentMode = newValue
            } else {
                super.contentMode = newValue
            }
        }
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            self.img?.frame = CGRectMake(0, 0, newValue.size.width, newValue.size.height)
        }
    }
    
    // MARK: - Lifecycle
    
    /**
    *  Init self
    *
    *  @return self
    */
    init() {
        super.init(frame: CGRectZero)
        self.setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    /**
    *  Init self with frame
    *
    *  @param frame
    *
    *  @return self
    */
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        let img = UIImageView(frame: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))
        img.contentMode = .Center
        self.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(img)
        
        self.clipsToBounds = true
        
        self.img = img
    }
    
    // MARK: Automatic Animate
    
    /**
    *  Automatic Animate Fill to Fit
    *
    *  @param frame
    *  @param duration
    *  @param delay
    */
    func animateToScaleAspectFitToFrame(frame: CGRect, duration: NSTimeInterval, delay: NSTimeInterval)
    {
        if let _ = self.image {
            self.initToScaleAspectFitToFrame(frame)
            
            UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                self.animaticToScaleAspectFit()
            }, completion: nil)

        } else {
            print("ERROR, UIImageView %@ don't have UIImage", self)
        }
    }

    /**
    *  Automatic Animate Fit to Fill
    *
    *  @param frame
    *  @param duration
    *  @param delay
    */
    func animateToScaleAspectFillToFrame(frame: CGRect, duration: NSTimeInterval, delay: NSTimeInterval)
    {
        if let _ = self.image {
            self.initToScaleAspectFitToFrame(frame)

            UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                self.animaticToScaleAspectFit()
            }, completion: { (complete) -> Void in
                self.animateFinishToScaleAspectFill()
            })
        } else {
            print("ERROR, UIImageView %@ don't have UIImage", self)
        }
    }
    
    /**
    *  Automatic Animate Fill to Fit with completion
    *
    *  @param frame
    *  @param duration
    *  @param delay
    *  @param completion
    */
    func animateToScaleAspectFitToFrame(frame: CGRect, duration: NSTimeInterval, delay: NSTimeInterval, completion: (Bool -> Void)?)
    {
        if let _ = self.image {
            self.initToScaleAspectFitToFrame(frame)
            
            UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                self.animaticToScaleAspectFit()
            }, completion: { (complete) -> Void in
                if let completion = completion {
                    completion(complete)
                }
            })
        } else {
            if let completion = completion {
                completion(true)
            }
        
            print("ERROR, UIImageView %@ don't have UIImage", self)
        }
    }
    
    /**
    *  Automatic Animate Fit to Fill with completion
    *
    *  @param frame
    *  @param duration
    *  @param delay
    *  @param completion
    */
    func animateToScaleAspectFillToFrame(frame: CGRect, duration: NSTimeInterval, delay: NSTimeInterval, completion: (Bool -> Void)?)
    {
        if let _ = self.image {
            self.initToScaleAspectFillToFrame(frame)
            
            UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                self.animaticToScaleAspectFill()
            }, completion: { (complete) -> Void in
                self.animateFinishToScaleAspectFill()
                
                if let completion = completion {
                    completion(complete)
                }
            })
        } else {
            if let completion = completion {
                completion(true)
            }
            
            print("ERROR, UIImageView %@ don't have UIImage", self)
        }
    }
    
    // MARK: Manual Animate
    
    // MARK: Init Function
    
    /**
    *  Init Manual Function Fit
    *
    *  @param newFrame
    */
    func initToScaleAspectFitToFrame(newFrame: CGRect)
    {
        guard let img = self.img else {
            return
        }
        
        if let ratioImg = imgRatio() {
            if self.choiseFunctionWithRationImg(ratioImg, newFrame: self.frame) {
                img.frame = CGRectMake( -(self.frame.size.height * ratioImg - self.frame.size.width) / 2.0, 0, self.frame.size.height * ratioImg, self.frame.size.height);
            }else{
                img.frame = CGRectMake(0, -(self.frame.size.width / ratioImg - self.frame.size.height) / 2.0, self.frame.size.width, self.frame.size.width / ratioImg);
            }
        } else {
            print("ERROR, UIImageView %@ don't have UIImage", self)
        }
        
        self.contentMode = .ScaleAspectFit
        
        self.newFrameImg = CGRectMake(0, 0, newFrame.size.width, newFrame.size.height)
        self.newFrameWrapper = newFrame
    }
    
    func imgRatio() -> CGFloat? {
        guard let image = self.image else {
            return nil
        }
        
        return (image.size.width) / (image.size.height);
    }
    
    /**
    *  Init Manual Function Fill
    *
    *  @param newFrame
    */
    func initToScaleAspectFillToFrame(newFrame: CGRect)
    {
        if let ratioImg = imgRatio() {
            if self.choiseFunctionWithRationImg(ratioImg, newFrame: self.frame) {
                self.newFrameImg = CGRectMake( -(newFrame.size.height * ratioImg - newFrame.size.width) / 2.0, 0, newFrame.size.height * ratioImg, newFrame.size.height);
            }else{
                self.newFrameImg = CGRectMake(0, -(newFrame.size.width / ratioImg - newFrame.size.height) / 2.0, newFrame.size.width, newFrame.size.width / ratioImg);
            }
        }else{
            print("ERROR, UIImageView %@ don't have UIImage", self)
        }
        
        self.newFrameWrapper = newFrame;
    }
    
    // MARK: Animatic Function
    
    /**
    *  Animatic Fucntion Fit
    */
    func animaticToScaleAspectFit()
    {
        guard let img = self.img else {
            return
        }
        
        if let newFrameImg = self.newFrameImg {
            img.frame = newFrameImg
        }
        
        if let newFrameWrapper = self.newFrameWrapper {
            super.frame = newFrameWrapper
        }
    }
    
    /**
    *  Animatic Function Fill
    */
    func animaticToScaleAspectFill()
    {
        guard let img = self.img else {
            return
        }
        
        if let newFrameImg = self.newFrameImg {
            img.frame = newFrameImg
        }
        
        if let newFrameWrapper = self.newFrameWrapper {
            super.frame = newFrameWrapper
        }
    }
    
    // MARK: Last Function
    
    /**
    *  Last Function Fit
    */
    func animateFinishToScaleAspectFit()
    {
    //
    // Fake function
    //
    }
    
    /**
    *  Last Function Fill
    */
    func animateFinishToScaleAspectFill() {
        guard let img = self.img else {
            return
        }
        
        img.contentMode = .ScaleAspectFill;
        img.frame  = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    }
    
    // MARK: Private
    
    func choiseFunctionWithRationImg(ratioImg: CGFloat, newFrame: CGRect) -> Bool
    {
        var resultat = false
        let ratioSelf = (newFrame.size.width) / (newFrame.size.height);
    
        if (ratioImg < 1) {
            if (ratioImg > ratioSelf) {
                resultat = true
            }
        } else if (ratioImg > ratioSelf ) {
            resultat = true
        }
        
        return resultat
    }
}