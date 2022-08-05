import type { NextPage } from 'next';
import dynamic from "next/dynamic";
import Head from 'next/head';
import { useEffect, useState } from 'react';
import GameContainer from '../components/GameContainer';
import { GameProvider } from "../components/GameProvider";




const GameCanvas = dynamic(() => import("../components/GameCanvas"), {
    ssr: false,
});

type WindowSize = {
    width: number | undefined;
    height: number | undefined;
};

const Home: NextPage = () => {

    const [windowSize, setWindowSize] = useState<WindowSize>({
        width: undefined,
        height: undefined,
    });
    useEffect(() => {
        const handleResize = () => setWindowSize({
            width: window.innerWidth,
            height: window.innerHeight,
        });
        window.addEventListener("resize", handleResize);
        handleResize();
        return () => window.removeEventListener("resize", handleResize);
    }, []);

    const canvasSizeMax = 800;
    let canvasSize = 0;
    if (windowSize.width === undefined || windowSize.height === undefined) {
        canvasSize = canvasSizeMax;
    } else if (windowSize.width >= windowSize.height) {
        canvasSize = Math.min(canvasSizeMax, Math.floor(windowSize.height * 0.7));
    } else {
        canvasSize = Math.min(canvasSizeMax, Math.floor(windowSize.width * 0.85));
    }

    return (
        <div>
            <Head>
                <title>DogCat</title>
                <meta name="description" content="Basically two-ended snake" />
                <link rel="icon" href="/favicon.ico" />
            </Head>
            <GameProvider rows={25} columns={25}>
                <GameContainer>
                    <GameCanvas width={canvasSize} height={canvasSize} />
                </GameContainer>
            </GameProvider>
        </div>
    )
}

export default Home
