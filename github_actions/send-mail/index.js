const core = require('@actions/core');
const nodemailer = require('nodemailer');

async function run() {
    try {
        const to = core.getInput('to');
        const subject = core.getInput('subject');
        const body = core.getInput('body');

        const user = process.env.GMAIL_USER;
        const pass = process.env.GMAIL_PASS;

        let transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: { user, pass },
        });

        await transporter.sendMail({
            from: user,
            to,
            subject,
            text: body
        });

        console.log("Correo enviado");
    } catch (error) {
        core.setFailed(error.message);
    }
}

run();
