const sharp = require('sharp');
const fs = require('fs');

async function processImages() {
    const iconPath = 'C:\\Users\\adity\\Downloads\\HAND CREDIT _ WEBSITE FILES\\HAND CREDIT _ WEBSITE FILES\\ICON\\HAND CREDIT _ offwhite.svg';
    const splashPath = 'C:\\Users\\adity\\Downloads\\HAND CREDIT _ WEBSITE FILES\\HAND CREDIT _ WEBSITE FILES\\LOGO\\HAND CREDIT _ OFFWHITE.svg';
    
    // Process Icon: We want to extract the logo, trim the excess padding, and put it on a 1024x1024 canvas.
    // Wait, the SVG has an off-white background inside it? Let's render it first, trim, and then resize.
    
    await sharp(iconPath, {})
        .trim({ threshold: 10 }) // Removes background if it's uniform
        .resize(800, 800, { fit: 'contain', background: { r: 254, g: 253, b: 248, alpha: 1 } }) // FEFDF8
        .extend({
            top: 112, bottom: 112, left: 112, right: 112,
            background: { r: 254, g: 253, b: 248, alpha: 1 }
        })
        .toFile('assets/icon/app_icon.png');
        
    console.log('App icon generated!');

    // Process Splash: Make it 1920x1920 for high res
    await sharp(splashPath, {})
        .trim({ threshold: 10 })
        .resize(1000, 1000, { fit: 'contain', background: { r: 254, g: 253, b: 248, alpha: 1 } })
        .extend({
            top: 460, bottom: 460, left: 460, right: 460,
            background: { r: 254, g: 253, b: 248, alpha: 1 }
        })
        .toFile('assets/images/android12_splash.png');
        
    console.log('Splash generated!');
}

processImages().catch(console.error);
