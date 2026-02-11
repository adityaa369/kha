const axios = require('axios');

const sendOtp = async (phone, otp) => {
    // MSG91 API call to send OTP
    // Placeholder until credentials are provided
    console.log(`Sending OTP ${otp} to ${phone} via MSG91`);

    if (process.env.MSG91_AUTH_KEY === 'your_msg91_auth_key') {
        return { success: true, message: 'OTP sent (Simulation)', msg91_response: null };
    }

    try {
        const response = await axios.get(`https://api.msg91.com/api/v5/otp`, {
            params: {
                template_id: process.env.MSG91_TEMPLATE_ID,
                mobile: `91${phone}`,
                authkey: process.env.MSG91_AUTH_KEY,
                otp: otp
            }
        });
        return { success: true, response: response.data };
    } catch (error) {
        console.error('MSG91 Send OTP Error:', error.message);
        return { success: false, error: error.message };
    }
};

const verifyAccessToken = async (accessToken) => {
    try {
        const response = await axios.post('https://api.msg91.com/api/v5/widget/verifyAccessToken', {
            'access-token': accessToken
        }, {
            headers: {
                'authkey': process.env.MSG91_AUTH_KEY,
                'Content-Type': 'application/json'
            }
        });

        if (response.data.type === 'success') {
            return {
                success: true,
                mobile: response.data.mobile_number,
                response: response.data
            };
        }
        return { success: false, message: response.data.message || 'Invalid token' };
    } catch (error) {
        console.error('MSG91 Verify Token Error:', error.message);
        return { success: false, error: error.message };
    }
};

module.exports = { sendOtp, verifyOtp, verifyAccessToken };
